import { LightningElement, track, wire } from 'lwc';
import fetchCameraSettings from '@salesforce/apex/SiteIPCamsController.getCameraSettings';
import getCameraCredentials from '@salesforce/apex/SiteIPCamsController.getCameraCredentials';
import IPCamsResources from "@salesforce/resourceUrl/IPCams";
import headerLabel from '@salesforce/label/c.Watch_the_production_of_INTERPIPE_products_online';

export default class CameraFeedSwitcher extends LightningElement {
    @track selectedCameraUrl;
    @track selectedCameraName;
    @track cameraList = [];
    @track credentials;
    @track isLoading = false;

    labels = {
        header: headerLabel,
    };

    @wire(fetchCameraSettings)
    wiredCameraSettings({ error, data }) {
        if (data) {
            this.cameraList = data.map(cameraSetting => {
                const thumbnailUrl = IPCamsResources +'/'+ cameraSetting.Preview_IMG__c;
                return {
                    id: cameraSetting.Camera_Id__c,
                    name: cameraSetting.Description__c,
                    thumbnail: thumbnailUrl,
                    streamUrl: cameraSetting.IP_Camera_URL__c
                };
            });
            this.switchCameraFeed(this.cameraList[0]);
        } else if (error) {
            console.error('Error fetching camera settings:', error);
        }
    }
    @wire(getCameraCredentials)
    wiredCredentials({ error, data }) {
        if (data) {
            this.credentials = JSON.parse(data);
        } else if (error) {
            console.error('Error fetching credentials:', error);
        }
    }
    handleCameraSelection(event) {
        const cameraId = event.currentTarget.dataset.id;
        const selectedCamera = this.cameraList.find(camera => camera.id == cameraId);

        if (selectedCamera) {
            this.applyCameraSelectionStyle(event.currentTarget);
            this.switchCameraFeed(selectedCamera);
        }
    }

    applyCameraSelectionStyle(selectedElement) {
        this.template.querySelectorAll('.camera-item').forEach(el => {
            el.classList.remove('selected');
        });
        selectedElement.classList.add('selected');
    }

    switchCameraFeed(selectedCamera) {
        this.isLoading = true; // Show spinner
        this.stopCameraStreamRefresh();
        this.selectedCameraName = selectedCamera.name;
        this.startCameraStreamRefresh(selectedCamera.streamUrl);
    }

    async fetchStreamImage(endpoint) {
        if (!this.credentials) {
            console.error('No credentials available');
            return;
        }
        const { username, password } = this.credentials;
        const credentials = btoa(`${username}:${password}`);
        try {
            const response = await fetch(endpoint, {
                method: 'GET',
                headers: {
                    'Authorization': `Basic ${credentials}`,
                }
            });

            if (response.ok) {
                const responseImage = await response.blob();
                this.selectedCameraUrl = URL.createObjectURL(responseImage);
                this.isLoading = false; 
            } else {
                this.isLoading = false; 
                throw new Error(`Request failed: ${response.statusText}`);
            }
        } catch (error) {
            this.isLoading = false;
            console.error('Network error:', error);
        }
    }

    startCameraStreamRefresh(streamUrl) {
        this.refreshIntervalId = setInterval(() => this.fetchStreamImage(streamUrl), 1000);
    }

    stopCameraStreamRefresh() {
        clearInterval(this.refreshIntervalId);
    }

    disconnectedCallback() {
        this.stopCameraStreamRefresh();
    }
}