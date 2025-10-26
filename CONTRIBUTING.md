# Guide de contribution

Merci de votre intérêt pour contribuer au projet Infomaniak Kubernetes Lab.

## Comment contribuer

### Signaler un bug

1. Vérifier qu'il n'existe pas déjà dans les issues
2. Créer un nouveau issue avec :
   - Description claire du problème
   - Steps to reproduce
   - Comportement attendu vs actuel
   - Version de Terraform/kubectl
   - Logs pertinents

### Proposer une amélioration

1. Créer un issue pour discuter de l'amélioration
2. Attendre validation avant de commencer le développement
3. Suivre les guidelines de code

### Soumettre une Pull Request

1. Fork le repository
2. Créer une branche depuis `main` :
   ```bash
   git checkout -b feature/ma-fonctionnalite
   ```
3. Faire vos modifications
4. Tester localement
5. Commit avec un message descriptif
6. Push et créer la Pull Request

## Standards de code

### Terraform

- Utiliser `terraform fmt` avant de commit
- Valider avec `terraform validate`
- Documenter les variables avec descriptions
- Utiliser des noms explicites
- Suivre les best practices Terraform

### Shell Scripts

- Utiliser `#!/bin/bash` avec `set -e`
- Commenter les sections importantes
- Gérer les erreurs proprement
- Tester sur différentes plateformes si possible

### Kubernetes Manifests

- Utiliser YAML valide
- Inclure labels appropriés
- Définir les ressources (requests/limits)
- Documenter l'usage dans les commentaires

## Tests

Avant de soumettre une PR :

1. Tester le démarrage/arrêt du lab
2. Vérifier que les exemples fonctionnent
3. Valider les coûts estimés
4. Tester les scripts

## Documentation

- Mettre à jour README.md si nécessaire
- Ajouter des exemples dans docs/
- Documenter les nouvelles fonctionnalités
- Vérifier la syntaxe Markdown

## Commit Messages

Format recommandé :

```
type(scope): description courte

Description plus détaillée si nécessaire

Fixes #123
```

Types :
- `feat`: Nouvelle fonctionnalité
- `fix`: Correction de bug
- `docs`: Documentation
- `style`: Formatage, pas de changement de code
- `refactor`: Refactoring
- `test`: Ajout de tests
- `chore`: Maintenance

Exemples :
```
feat(terraform): ajouter support pour node pool GPU personnalisé
fix(scripts): corriger calcul des coûts dans lab-status.sh
docs(quickstart): améliorer guide de démarrage
```

## Review Process

1. Un mainteneur reviewera votre PR
2. Des modifications peuvent être demandées
3. Une fois approuvée, la PR sera mergée

## Code of Conduct

- Respecter tous les contributeurs
- Donner du feedback constructif
- Accepter les critiques constructives
- Focus sur ce qui est le mieux pour le projet

## Licence

En contribuant, vous acceptez que vos contributions soient sous licence MIT.
