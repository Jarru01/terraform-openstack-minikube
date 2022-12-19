# Repozitar obsahuje terraform scripty, sluziace primarne na vytvorenie instancie ubuntu VM, vytvorenie minikube clustera s 3 nodami na ubuntu VM a povolenie sietovej prevadzky na ubuntu VM.

locals.tf               - subor sluzi na vytvorenie premennych pre parametre ktore v programe casto vyuzivame, vdaka comu ich je mozne potom zmenit na jednom mieste<br />
providers.tf            - definuje cloud providerov s ktorymi interagujeme a potrebne parametre<br />
main.tf                 - obsahuje konfiguraciu objektov ktore sa maju vytvorit<br />
variables.tf            - podobne ako locals.tf sluzi na ukladanie casto pouzivanych parametrov do premennych. <br />
terraform.auto.tfvars   - sluzi na naplnenie zadefinovanych premennych v subore variables.tf

* Na aplikovanie konfiguracie na openstack server je najprv potrebne inicializovat terraform pomocou prikazu terraform init.
* Nasledne je vhodne pouzit prikaz terraform plan, na skontrolovanie objektov ktore budu v openstacku nakonfigurovane. 
* Nakoniec prikazom terraform apply aplikujeme konfiguraciu zo scriptov na openstack.
* Na overenie funkcionality sa je mozne pomocou programu putty prihlasit pomocou ssh kluca a ip adresy vm na vytvorene ubuntu v openstacku.
