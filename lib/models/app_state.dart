import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'invoice_model.dart';

class AppState extends StateNotifier<InvoiceModel> {
  AppState() : super(InvoiceModel.empty());

  void updateCustomerName(String name) {
    state = state.copyWith(customerName: name);
  }

  void updateItems(List<InvoiceItem> items) {
    state = state.copyWith(items: items);
  }

  void addItem(InvoiceItem item) {
    final newItems = List<InvoiceItem>.from(state.items)..add(item);
    state = state.copyWith(items: newItems);
  }

  void removeItem(int index) {
    final newItems = List<InvoiceItem>.from(state.items)..removeAt(index);
    state = state.copyWith(items: newItems);
  }

  void updateItem(int index, InvoiceItem item) {
    final newItems = List<InvoiceItem>.from(state.items);
    newItems[index] = item;
    state = state.copyWith(items: newItems);
  }

  void clearInvoice() {
    state = InvoiceModel.empty();
  }

  void setInvoice(InvoiceModel invoice) {
    state = invoice;
  }
}

final appStateProvider = StateNotifierProvider<AppState, InvoiceModel>((ref) {
  return AppState();
});
