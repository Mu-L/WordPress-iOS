import SwiftUI

struct SubscribersMenu: View {
    @ObservedObject var viewModel: SubscribersViewModel

    var body: some View {
        Menu {
            sorting
            filterByEmailSubscriptionType
            filterByPaymenetType
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }

    private var sorting: some View {
        Menu {
            Section {
                Picker("", selection: $viewModel.parameters.sortField) {
                    Text(Strings.defaultSort).tag(Optional<SortField>.none)
                    ForEach([SortField.dateSubscribed, .email, .name], id: \.self) { item in
                        Text(item.localizedTitle).tag(item)
                    }
                }
                .pickerStyle(.inline)
            }
            Section {
                Picker("", selection: viewModel.makeSortOrderBinding()) {
                    ForEach([SortOrder.descending, .ascending], id: \.self) { item in
                        Text(item.localizedTitle).tag(item)
                    }
                }
                .pickerStyle(.inline)
            }
        } label: {
            Button(action: {}, label: {
                Text(SharedStrings.Misc.sortBy)
                Text(viewModel.parameters.sortField?.localizedTitle ?? Strings.defaultSort)
                Image(systemName: "arrow.up.arrow.down")
            })
        }
    }

    private var filterByEmailSubscriptionType: some View {
        Picker(selection: $viewModel.parameters.subscriptionTypeFilter) {
            Text(Strings.showAll).tag(Optional<FilterSubscriptionType>.none)
            ForEach(FilterSubscriptionType.allCases, id: \.self) { item in
                Text(item.localizedTitle).tag(item)
            }
        } label: {
            Button(action: {}, label: {
                Text(Strings.filterByEmailSubscription)
                Text(viewModel.parameters.subscriptionTypeFilter?.localizedTitle ?? Strings.showAll)
                Image(systemName: "mail")
            })
        }
        .pickerStyle(.menu)
    }

    private var filterByPaymenetType: some View {
        Picker(selection: $viewModel.parameters.paymentTypeFilter) {
            Text(Strings.showAll).tag(Optional<FilterPaymentType>.none)
            ForEach(FilterPaymentType.allCases, id: \.self) { item in
                Text(item.localizedTitle).tag(item)
            }
        } label: {
            Button(action: {}, label: {
                Text(Strings.filterByPaymentType)
                Text(viewModel.parameters.paymentTypeFilter?.localizedTitle ?? Strings.showAll)
                Image(systemName: "line.3.horizontal.decrease")
            })
        }
        .pickerStyle(.menu)
    }
}

private typealias SortField = PeopleServiceRemote.SubscribersParameters.SortField
private typealias SortOrder = PeopleServiceRemote.SubscribersParameters.SortOrder
private typealias FilterSubscriptionType = PeopleServiceRemote.SubscribersParameters.FilterSubscriptionType
private typealias FilterPaymentType = PeopleServiceRemote.SubscribersParameters.FilterPaymentType

private enum Strings {
    static let filterByEmailSubscription = NSLocalizedString("subscribers.filter.emailSubscription", value: "Email Subscription", comment: "Empty state view title")
    static let filterByPaymentType = NSLocalizedString("subscribers.filter.paymentType", value: "Payment", comment: "Empty state view title")
    static let showAll = SharedStrings.Misc.default(value: SharedStrings.Misc.showAll)
    static let defaultSort = SharedStrings.Misc.default(value: SortField.dateSubscribed.localizedTitle)
}
