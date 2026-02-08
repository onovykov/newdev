sf project deploy start --metadata-dir C:\Users\aleksandr.novikov\InterpipeNewDev\DestructDeploy --target-org NewDev --dry-run --test-level NoTestRun
sf project deploy start --metadata-dir C:\Users\aleksandr.novikov\InterpipeNewDev\DestructDeploy --target-org NewDev --test-level NoTestRun

rm force-app/main/default/classes/ProdSteel*.cls
rm force-app/main/default/classes/ProdSteel*.cls-meta.xml

git commit -m "Remove obsolete ProdSteel Apex classes (project closed)"
