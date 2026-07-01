# Terraform Drupal Infrastructure

Infrastructure Terraform pour déployer une application Drupal sur AWS avec un module compute et un module RDS.

## Structure

- `main.tf` : appel des modules core et ressource `aws_security_group.web`
- `network.tf` : VPC, subnets publics/privés, Internet Gateway, route table, DB subnet group
- `providers.tf` : configuration des versions Terraform et du provider AWS
- `variables.tf` : variables globales du projet
- `outputs.tf` : outputs globaux du projet
- `drupal-app-user-data-serv.sh` : script `user_data` séparé pour l’instance web
- `modules/compute/` : module pour l’instance EC2 web
- `modules/rds/` : module pour la base de données RDS

## Prérequis

- Terraform >= 1.5.0
- AWS CLI configuré avec des identifiants valides
- Compte AWS dans la région `eu-west-3`

## Utilisation

1. Initialiser Terraform :
   ```bash
   terraform init
   ```

2. Vérifier le plan :
   ```bash
   terraform plan
   ```

3. Appliquer les changements :
   ```bash
   terraform apply
   ```

## Modules

- `modules/compute` : gère l’instance EC2 web et reçoit `user_data` depuis la racine
- `modules/rds` : gère l’instance RDS et le security group de la base

## Notes

- Le script de configuration de Drupal est stocké dans `drupal-app-user-data-serv.sh`
- Les variables par défaut sont définies dans `variables.tf`
- Les versions du provider et de Terraform sont verrouillées dans `providers.tf`

## Suggestion de commit

Commit message :

```
refactor(terraform): reorganize root layout and add README
```
