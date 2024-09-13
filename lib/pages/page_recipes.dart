import 'package:fluent_ui/fluent_ui.dart';
import 'widgets/archive_button.dart';
import 'widgets/tag_input.dart';
import '../state/stores/recipes/recipes_model.dart';
import '../state/stores/recipes/recipes_store.dart';
import "widgets/datatable.dart";
import "widgets/tabbed_modal.dart";

// ignore: must_be_immutable
class PageOne extends StatelessWidget {
  Recipe newRecipe = Recipe.fromJson({});
  Recipe editRecipe = Recipe.fromJson({});

  PageOne({super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: DataTable<Recipe>(
        items: recipes.present,
        labels: const ["price", "components number"],
        actions: [
          DataTableAction(
              callback: (_) {
                addNewModal(context);
              },
              icon: FluentIcons.add,
              title: "Add new"),
          DataTableAction(
              callback: (ids) {
                for (var id in ids) {
                  recipes.archive(id);
                }
              },
              icon: FluentIcons.archive,
              title: "Archive Selected")
        ],
        furtherActions: [
          const SizedBox(width: 5),
          Checkbox(
            style: const CheckboxThemeData(icon: FluentIcons.archive),
            checked: recipes.showArchived,
            onChanged: recipes.showArchivedChanged,
          )
        ],
        onSelect: (item) {
          editModal(item, context);
        },
      ),
    );
  }

  void editModal(Recipe item, BuildContext context) {
    editRecipe = item;
    showTabbedModal(context: context, tabs: [
      TabbedModal(
        title: "Edit",
        icon: FluentIcons.edit,
        closable: true,
        content: () {
          return [
            InfoLabel(
              label: "Recipe name:",
              child: TextBox(
                controller: TextEditingController(text: editRecipe.title),
                placeholder: "Type the name of recipe",
                onChanged: (val) {
                  editRecipe.title = val;
                },
              ),
            ),
            InfoLabel(
              label: "Estimated price:",
              child: NumberBox(
                value: editRecipe.estimatedPrice,
                placeholder: "Recipe price",
                onChanged: (val) {
                  editRecipe.estimatedPrice = val ?? 0;
                },
              ),
            ),
            InfoLabel(
              label: "Details:",
              child: TextBox(
                controller: TextEditingController(text: editRecipe.details),
                expands: true,
                minLines: null,
                maxLines: null,
                placeholder: "Recipe details",
                onChanged: (val) {
                  editRecipe.details = val;
                },
              ),
            ),
            InfoLabel(
              label: "tag input GPT:",
              child: TagInputWidget(
                initialValue: [...editRecipe.components.map((e) => TagInputItem(value: e.name, label: e.name))],
                limit: 4,
                strict: false,
                placeholder: "Enter components",
                noResultsMessage: "",
                onChanged: (tags) {
                  editRecipe.components = tags.map((e) => Component.fromJson({"name": e.label})).toList();
                },
                suggestions: ['Fluttera', 'Darta', 'Widgeta', 'Customa', 'FluentUIa']
                    .map((e) => TagInputItem(value: e, label: e))
                    .toList(),
              ),
            ),
          ];
        },
        actions: [
          archiveButton(item, recipes),
          TabAction(
              text: "Save",
              callback: () {
                recipes.modify(editRecipe);
                return true;
              },
              icon: FluentIcons.save)
        ],
      )
    ]);
  }

  void addNewModal(BuildContext context) {
    newRecipe = Recipe.fromJson({});
    return showTabbedModal(
      context: context,
      tabs: [
        TabbedModal(
          title: "Add new recipe",
          icon: FluentIcons.add,
          closable: true,
          content: () => [
            InfoLabel(
              label: "Recipe name:",
              child: TextBox(
                controller: TextEditingController(text: ""),
                placeholder: "Type the name of recipe",
                onChanged: (val) {
                  newRecipe.title = val;
                },
                onSubmitted: (_) {
                  if (newRecipe.title.isEmpty) return;
                  recipes.add(Recipe.fromJson(newRecipe.toJson()));
                  Navigator.pop(context);
                },
              ),
            ),
          ],
          actions: [
            TabAction(
                text: "Add Recipe",
                callback: () {
                  if (newRecipe.title.isEmpty) return false;
                  recipes.add(Recipe.fromJson(newRecipe.toJson()));
                  return true;
                },
                icon: FluentIcons.add)
          ],
        ),
      ],
    );
  }
}
