import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import requestChange from '@salesforce/apex/ScrapSlotChangeService.requestChange';
import getSlotDetails from '@salesforce/apex/ScrapSlotChangeService.getSlotDetails';
import listDrivers from '@salesforce/apex/ScrapSlotChangeService.listDrivers';
import listTrucks from '@salesforce/apex/ScrapSlotChangeService.listTrucks';

export default class ScrapEditPassModal extends LightningElement {
    @api order;
    @api supplierId;

    @track saving = false;

    @track drivers = [];
    @track tractors = [];
    @track trailers = [];

    driverById = new Map();
    tractorById = new Map();
    trailerById = new Map();

    @track driverId = null;
    @track tractorId = null;
    @track trailerId = null;
    @track trailerRemove = false;
    @track comment = '';

    async connectedCallback() {
        // клон, щоб Locker не лаявся на Proxy
        // eslint-disable-next-line no-console
        console.log('[ScrapEditPassModal] init order=', JSON.parse(JSON.stringify(this.order)));

        try {
            // 1) Підтягнути повні дані слота
            if (this.order?.id) {
                const full = await getSlotDetails({ slotId: this.order.id });
                // мерджимо (full перекриває голі поля з parent)
                this.order = Object.assign({}, this.order || {}, full || {});
                // eslint-disable-next-line no-console
                console.log('[ScrapEditPassModal] enriched order=', JSON.parse(JSON.stringify(this.order)));
            }

            // 2) Довідники
            const accId = this.supplierId || this.order?.supplierId;
            if (accId) {
                const [d, tr, tl] = await Promise.all([
                    listDrivers({ supplierId: accId }),
                    listTrucks({ supplierId: accId, truckType: 'Truck' }),
                    listTrucks({ supplierId: accId, truckType: 'Trailer' })
                ]);
                this.drivers = d || [];
                this.tractors = tr || [];
                this.trailers = tl || [];

                this.driverById = new Map(this.drivers.map(x => [x.id, x]));
                this.tractorById = new Map(this.tractors.map(x => [x.id, x]));
                this.trailerById = new Map(this.trailers.map(x => [x.id, x]));

                // eslint-disable-next-line no-console
                console.log('[ScrapEditPassModal] lookups', {
                    supplierId: accId,
                    drivers: this.drivers, tractors: this.tractors, trailers: this.trailers
                });
            }
        } catch (e) {
            this._toast('Помилка', this._err(e, 'Не вдалося завантажити дані слота/довідники'), 'error');
        }
    }

    // ——— options (прибираємо поточні значення) ———
    get driverOptions() {
        const currentId = this.order?.driverId || null;
        const base = [{ label: '— Без змін —', value: '' }];
        const items = (this.drivers || [])
            .filter(x => x?.id !== currentId)
            .map(x => ({ label: `${x.name}${x.phone ? ' • ' + x.phone : ''}`, value: x.id }));
        return base.concat(items);
    }
    get tractorOptions() {
        const currentId = this.order?.truckId || null;
        const base = [{ label: '— Без змін —', value: '' }];
        const items = (this.tractors || [])
            .filter(x => x?.id !== currentId)
            .map(x => ({ label: `${x.model || 'Тягач'} • ${x.plate}${x.tonnage ? ' • ' + x.tonnage + ' т' : ''}`, value: x.id }));
        return base.concat(items);
    }
    get trailerOptions() {
        const currentId = this.order?.trailerId || null;
        const base = [{ label: '— Без змін —', value: '' }];
        const items = (this.trailers || [])
            .filter(x => x?.id !== currentId)
            .map(x => ({ label: `${x.model || 'Причіп'} • ${x.plate}${x.tonnage ? ' • ' + x.tonnage + ' т' : ''}`, value: x.id }));
        return base.concat(items);
    }

    // ——— handlers ———
    onDriverChange(e){ this.driverId  = e?.detail?.value || null; }
    onTractorChange(e){ this.tractorId = e?.detail?.value || null; }
    onTrailerChange(e){ this.trailerId = e?.detail?.value || null; if (this.trailerId) this.trailerRemove = false; }
    onTrailerRemoveToggle(e){ this.trailerRemove = !!e?.target?.checked; if (this.trailerRemove) this.trailerId = null; }
    onComment(e){ this.comment = e?.target?.value || ''; }

    // ——— save state ———
    get saveDisabled(){
        const driverChanged  = !!this.driverId;
        const tractorChanged = !!this.tractorId;
        const trailerChanged = !!this.trailerId;
        const trailerRemoved = !!this.order?.hasTrailer && this.trailerRemove === true;
        return this.saving || !(driverChanged || tractorChanged || trailerChanged || trailerRemoved);
    }

    async save(){
        if (this.saveDisabled){
            this._toast('Немає змін', 'Виберіть, що саме змінити, перед збереженням.', 'warning');
            return;
        }
        this.saving = true;
        try{
            const payload = {
                slotId: this.order?.id,
                newDriverId:  this.driverId || null,
                newTractorId: this.tractorId || null,
                newTrailerId: this.trailerRemove ? null : (this.trailerId || null),
                comment: (this.comment || '').trim() || null
            };
            // eslint-disable-next-line no-console
            console.log('[ScrapEditPassModal] requestChange payload', JSON.parse(JSON.stringify(payload)));

            const dto = await requestChange(payload);
            // eslint-disable-next-line no-console
            console.log('[ScrapEditPassModal] requestChange result', JSON.parse(JSON.stringify(dto)));

            this._toast('Надіслано на погодження', 'Слот переведено у Requested, перепустку скинуто.', 'success');
            this.dispatchEvent(new CustomEvent('changed', { detail: dto, bubbles:true, composed:true }));
            this.close();
        }catch(e){
            this._toast('Помилка', this._err(e, 'Не вдалося надіслати зміни'), 'error');
        }finally{
            this.saving = false;
        }
    }

    close(){ this.dispatchEvent(new CustomEvent('close', { bubbles:true, composed:true })); }

    _toast(title, message, variant){ this.dispatchEvent(new ShowToastEvent({ title, message, variant })); }
    _err(e, fallback){ return e?.body?.message || e?.message || fallback || 'Сталася помилка'; }
}