# PhotoSwipe — Architecture V1

App iOS de tri de photos avec une interface à swipe.

## Périmètre V1

- Swipe **gauche** → la photo va dans la corbeille interne. **Droite** → la photo est gardée.
- Bouton **Annuler** pour revenir sur le dernier swipe.
- Filtres de catégorie : **Photos** et **Screenshots** (cumulables).
- Une seule pile triée par **date croissante** (des plus anciennes aux plus récentes).
- **Corbeille** : on peut récupérer des photos, puis tout supprimer en une seule confirmation iOS.
  Les photos supprimées restent 30 jours dans « Supprimés récemment ».

## Stack

| Élément | Choix |
|---|---|
| UI | SwiftUI |
| Photos | PhotoKit (`PHAsset`, `PHCachingImageManager`) |
| Persistance | SwiftData (décisions de tri) |
| État | `@Observable` (Observation) |
| Design | Liquid Glass (`glassEffect`, `.glass` / `.glassProminent`, `GlassEffectContainer`) |
| iOS minimum | 26.0 |

## Organisation du code

```
PhotoSwipe/
├── PhotoSwipeApp.swift          Point d'entrée, ModelContainer SwiftData
├── Models/
│   ├── SortDecision.swift       @Model : identifiant de la photo, décision (garder/corbeille), date
│   └── MediaCategory.swift      Enum des catégories (photo, screenshot)
├── Services/
│   └── PhotoLibraryService.swift  Autorisation, récupération filtrée, chargement d'images, suppression
├── ViewModels/
│   └── SortingViewModel.swift   File de photos à trier, décisions, undo, corbeille
└── Views/
    ├── RootView.swift           Choisit l'écran selon l'autorisation
    ├── PermissionView.swift     Demande d'accès à la photothèque
    ├── SortingView.swift        Écran principal : filtres, pile de cartes, boutons
    ├── SwipeCardView.swift      Une carte qu'on peut glisser
    ├── AssetImageView.swift     Affiche un PHAsset (chargement progressif, iCloud)
    └── TrashView.swift          Grille de la corbeille, récupération, suppression
```

## Flux de données

1. `PhotoLibraryService` récupère les `PHAsset` images, triées par `creationDate` croissante,
   filtrées par catégorie via `mediaSubtypes` (bit `photoScreenshot`).
2. `SortingViewModel` retire les photos déjà présentes dans SwiftData (`SortDecision`) → `queue`.
3. Un swipe crée une `SortDecision` et retire la photo de la file. L'undo supprime la décision
   et remet la photo en tête de pile.
4. La corbeille = les `SortDecision` dont la décision est `.trash`. « Tout supprimer » appelle
   `PHAssetChangeRequest.deleteAssets` (une seule alerte système), puis efface ces décisions.

## Design Liquid Glass

- Les boutons ✕ / ↩ / ♥ flottent **sur** la photo (le verre réfracte l'image) dans un `GlassEffectContainer`,
  avec `.glassEffect(.regular.interactive(), in: .circle)`.
- Filtres : `.glassProminent` (actif, teinté couleur d'accent) / `.glass` (inactif).
- Date de la photo : pastille en verre en haut de la carte, qui s'efface pendant le glissement.
- Barre de navigation et feuilles : Liquid Glass automatique du système.

## Points d'attention

- **Suppression groupée** : iOS demande une confirmation à chaque appel de suppression, d'où la corbeille interne.
- **Accès limité** : géré (on trie seulement les photos autorisées, avec un bandeau d'info).
- **iCloud** : `isNetworkAccessAllowed = true` + préchargement des cartes suivantes.

## Pistes V2

Vidéos, doublons et photos floues (Vision), tri par période, geste haut = favori, statistiques d'espace libéré.
