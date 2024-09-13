# Fluent Flutter Starter

Use this starter to build your next flutter app. It uses:
- Fluent UI theme
- a custom state management solution (that just work)
- kind-of strongly typed custom i18n solution
- Persistence solution that synchronizes with cloudflare backend


## Adding pages

Use `pages` directory, write the widget for your page, and add data in the `pages/index.dart` file.

## Localization

Look at the examples at `i18` directory.

## State management

You have 3 solutions:
- **State**: The state is just a dart class, so feel free to add any logic you feel necessary. For properties that you want to persist even after the application is closed, include them in `fromJson` and `toJson` method. otherwise, they would live in memory, and cleared once the application is closed.
- **stores**: This state is like a database, where the entries are inside a list, and each entry/document is modeled against a class that would contain the relevant logic. check the directory 'state/stores'.
- **ObservableState**: this is a standalone state that you can use anywhere, but it won't persist.

for more info look into "observable.dart" file.
