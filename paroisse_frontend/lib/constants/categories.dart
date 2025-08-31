// Catégories principales
const List<String> categories = [
  'Recette',
  'Dépense',
  'Autres',
];

// Mapping catégorie → sous-catégories autorisées
const Map<String, List<String>> sousCategoriesMap = {
  'Recette': ['Dons', 'Quête', 'Offrande', 'Autre'],
  'Dépense': ['Achat', 'Salaire', 'Autre'],
  'Autres': ['Divers'],
};

// Fonction utilitaire pour récupérer les sous-catégories d'une catégorie
List<String> getSousCategories(String categorie) {
  return sousCategoriesMap[categorie]?.toSet().toList() ?? ['Autre'];
}
