import SwiftUI
import SwiftData

// MARK: - CategoriesListView
struct CategoriesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TransactionCategory.name) private var categories: [TransactionCategory]
    @State private var isAddCategoryPresented = false
    @State private var selectedCategoryForEdit: TransactionCategory?

    var body: some View {
        NavigationStack {
            List {
                Section("Categorías de Gastos") {
                    ForEach(categories.filter { $0.categoryType == .expense }) { cat in
                        CategoryRow(category: cat)
                            .onTapGesture {
                                selectedCategoryForEdit = cat
                            }
                    }
                    .onDelete { indexSet in
                        deleteCategories(offsets: indexSet, type: .expense)
                    }
                }

                Section("Categorías de Ingresos") {
                    ForEach(categories.filter { $0.categoryType == .income }) { cat in
                        CategoryRow(category: cat)
                            .onTapGesture {
                                selectedCategoryForEdit = cat
                            }
                    }
                    .onDelete { indexSet in
                        deleteCategories(offsets: indexSet, type: .income)
                    }
                }
            }
            .navigationTitle("Categorías")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddCategoryPresented = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                    }
                }
            }
            .sheet(isPresented: $isAddCategoryPresented) {
                CategoryEditSheet(categoryToEdit: nil)
            }
            .sheet(item: $selectedCategoryForEdit) { cat in
                CategoryEditSheet(categoryToEdit: cat)
            }
        }
    }

    private func deleteCategories(offsets: IndexSet, type: TransactionType) {
        let filtered = categories.filter { $0.categoryType == type }
        for index in offsets {
            let cat = filtered[index]
            modelContext.delete(cat)
        }
        try? modelContext.save()
    }
}

// MARK: - CategoryRow
struct CategoryRow: View {
    let category: TransactionCategory

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: category.colorHex))
                    .frame(width: 38, height: 38)

                Image(systemName: category.iconName)
                    .font(.system(size: 16))
                    .foregroundStyle(.white)
            }

            Text(category.name)
                .font(.kashBodyBold)

            Spacer()

            if category.isDefault {
                Text("Predeterminada")
                    .font(.kashMicro)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - CategoryEditSheet
struct CategoryEditSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let categoryToEdit: TransactionCategory?

    @State private var name: String = ""
    @State private var selectedType: TransactionType = .expense
    @State private var selectedColorHex: String = "#3B82F6"
    @State private var selectedIcon: String = "cart.fill"

    private let availableColors = [
        "#10B981", "#3B82F6", "#F59E0B", "#EF4444", "#8B5CF6", "#EC4899", "#06B6D4", "#64748B"
    ]

    private let availableIcons = [
        "cart.fill", "house.fill", "fork.knife", "fuelpump.fill", "bag.fill",
        "cross.case.fill", "tv.fill", "airplane", "gift.fill", "book.fill",
        "dollarsign.circle.fill", "banknote.fill", "briefcase.fill", "creditcard.fill"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("Información") {
                    TextField("Nombre de la Categoría", text: $name)

                    Picker("Tipo de Transacción", selection: $selectedType) {
                        Text("Gasto").tag(TransactionType.expense)
                        Text("Ingreso").tag(TransactionType.income)
                    }
                }

                Section("Color e Ícono") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(availableColors, id: \.self) { hex in
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 34, height: 34)
                                    .overlay {
                                        if selectedColorHex == hex {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .onTapGesture {
                                        selectedColorHex = hex
                                    }
                            }
                        }
                        .padding(.vertical, 4)
                    }

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 14) {
                        ForEach(availableIcons, id: \.self) { icon in
                            ZStack {
                                Circle()
                                    .fill(selectedIcon == icon ? Color(hex: selectedColorHex) : Color.secondary.opacity(0.12))
                                    .frame(width: 44, height: 44)

                                Image(systemName: icon)
                                    .font(.system(size: 18))
                                    .foregroundStyle(selectedIcon == icon ? .white : .primary)
                            }
                            .onTapGesture {
                                selectedIcon = icon
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(categoryToEdit == nil ? "Nueva Categoría" : "Editar Categoría")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") {
                        UIApplication.endEditing()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveCategory()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let cat = categoryToEdit {
                    name = cat.name
                    selectedType = cat.categoryType
                    selectedColorHex = cat.colorHex
                    selectedIcon = cat.iconName
                }
            }
        }
    }

    private func saveCategory() {
        if let cat = categoryToEdit {
            cat.name = name
            cat.categoryType = selectedType
            cat.colorHex = selectedColorHex
            cat.iconName = selectedIcon
        } else {
            let newCat = TransactionCategory(
                name: name,
                iconName: selectedIcon,
                colorHex: selectedColorHex,
                categoryType: selectedType
            )
            modelContext.insert(newCat)
        }

        try? modelContext.save()
        dismiss()
    }
}
