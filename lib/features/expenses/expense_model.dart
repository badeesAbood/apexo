import 'package:apexo/core/model.dart';
import 'package:apexo/services/localization/locale.dart';
import 'package:intl/intl.dart';

class Expense extends Model {
  @override
  get labels {
    Map<String, String> buildingLabels = {
      "issuer": issuer,
      "status": paid ? txt("paid") : txt("due"),
      "month": DateFormat("MMM yyyy", locale.s.$code).format(date),
      "amount": amount.toString(),
    };
    for (var i = 0; i < tags.length; i++) {
      buildingLabels[List.generate(i + 1, (_) => "\u200B").join("")] = tags[i];
    }
    return buildingLabels;
  }

  @override
  String get title {
    return DateFormat("yyyy-MM-dd").format(date);
  }

  // id: id of the labwork (inherited from Model)
  // title: title of the labwork (inherited from Model)
  /* 1 */ String note = "";
  /* 2 */ double amount = 0;
  /* 3 */ bool paid = false;
  /* 4 */ DateTime date = DateTime.now();
  /* 5 */ String issuer = "";
  /* 6 */ String phoneNumber = "";
  /* 7 */ List<String> items = [];
  /* 8 */ List<String> tags = [];

  Expense.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    /* 1 */ note = json['note'] ?? note;
    /* 2 */ amount = double.parse((json["amount"] ?? amount).toString());
    /* 3 */ paid = json['paid'] ?? paid;
    /* 4 */ date = json["date"] != null ? DateTime.fromMillisecondsSinceEpoch(json["date"] * 60 * 60 * 1000) : date;
    /* 5 */ issuer = json['issuer'] ?? issuer;
    /* 6 */ phoneNumber = json['phoneNumber'] ?? phoneNumber;
    /* 7 */ items = List<String>.from(json["items"] ?? items);
    /* 8 */ tags = List<String>.from(json['tags'] ?? tags);
  }

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    final d = Expense.fromJson({});
    /* 1 */ if (note != d.note) json['note'] = note;
    /* 2 */ if (amount != d.amount) json['amount'] = amount;
    /* 3 */ if (paid != d.paid) json['paid'] = paid;
    /* 4 */ if (date != d.date) json['date'] = (date.millisecondsSinceEpoch / (60 * 60 * 1000)).round();
    /* 5 */ if (issuer != d.issuer) json['issuer'] = issuer;
    /* 6 */ if (phoneNumber != d.phoneNumber) json['phoneNumber'] = phoneNumber;
    /* 7 */ if (items.isNotEmpty) json['items'] = items;
    /* 8 */ if (tags.isNotEmpty) json['tags'] = tags;

    return json;
  }
}
