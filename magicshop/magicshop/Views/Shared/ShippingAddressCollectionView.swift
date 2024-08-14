import SwiftUI

struct ShippingAddressCollectionView: View {
    let dismissAction: () -> Void
    @EnvironmentObject var stripeService: StripeService
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var line1 = ""
    @State private var line2 = ""
    @State private var city = ""
    @State private var stateOrProvince = "AB"
    @State private var postalCode = ""
    @State private var countrySelection = "CA"
    @State private var isPostalCodeValid = true
    let unitedStates = ["Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado",
                        "Connecticut", "Delaware", "Florida", "Georgia", "Hawaii", "Idaho",
                        "Illinois", "Indiana", "Iowa", "Kansas", "Kentucky", "Louisiana",
                        "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota",
                        "Mississippi", "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire",
                        "New Jersey", "New Mexico", "New York", "North Carolina", "North Dakota", "Ohio",
                        "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island", "South Carolina",
                        "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin", "Wyoming"]

    var body: some View {
        Form {
            Section(header: Text("Address")) {
                TextField("First Name", text: $firstName)
                TextField("Last Name", text: $lastName)
                TextField("Line 1", text: $line1)
                TextField("Line 2", text: $line2)
                TextField("City", text: $city)
                Picker("Country", selection: $countrySelection) {
                    Text("🇺🇸").tag("US")
                    Text("🇨🇦").tag("CA")
                }
                .pickerStyle(SegmentedPickerStyle())
                if countrySelection == "US" {
                    Picker("State", selection: $stateOrProvince) {
                        ForEach(unitedStates, id: \.self) { state in
                            Text(state)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                } else if countrySelection == "CA" {
                    Picker("Province", selection: $stateOrProvince) {
                        Group {
                            Text("Alberta").tag("AB")
                            Text("British Columbia").tag("BC")
                            Text("Manitoba").tag("MB")
                            Text("New Brunswick").tag("NB")
                        }
                        Group {
                            Text("Newfoundland and Labrador").tag("NL")
                            Text("Nova Scotia").tag("NS")
                            Text("Ontario").tag("ON")
                            Text("Prince Edward Island").tag("PE")
                            Text("Quebec").tag("QC")
                        }
                        Group {
                            Text("Saskatchewan").tag("SK")
                            Text("Northwest Territories").tag("NT")
                            Text("Nunavut").tag("NU")
                            Text("Yukon").tag("YT")
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                TextField("Postal Code", text: $postalCode, onEditingChanged: { isEditing in
                    if !isEditing {
                        validatePostalCode()
                    }
                })
                .foregroundColor(isPostalCodeValid ? Color.primary : Constants.crayolaRedColor)
                .padding(.bottom)
            }
            HStack {
                Button("Cancel") {
                    dismissAction()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.red)
                .background(Color.clear)
                .buttonStyle(PlainButtonStyle())
                Divider()
                Button("Done") {
                    validatePostalCode()
                    if isPostalCodeValid {
                        stripeService.updateCustomerShippingInfo(
                            line1: line1,
                            line2: line2,
                            firstName: firstName,
                            lastName: lastName,
                            city: city,
                            stateOrProvince: stateOrProvince,
                            postalCode: postalCode,
                            country: countrySelection
                        )
                        dismissAction()
                    } else {
                        print("PLEASE CHANGE POSTAL CODE")
                    }
                }
                .disabled(firstName.isEmpty || lastName.isEmpty || line1.isEmpty || city.isEmpty || stateOrProvince.isEmpty)
                .frame(maxWidth: .infinity)
                .foregroundColor(.blue)
                .background(Color.clear)
                .buttonStyle(PlainButtonStyle())
                Spacer()
            }
        }
    }

    private func validatePostalCode() {
        if countrySelection == "US" {
            let zipCodeRegex = #"^\d{5}$|^\d{5}-\d{4}$"#
            isPostalCodeValid = NSPredicate(format: "SELF MATCHES %@", zipCodeRegex).evaluate(with: postalCode)
        } else if countrySelection == "CA" {
            let postalCodeRegex = #"^[A-Za-z]\d[A-Za-z][ -]?\d[A-Za-z]\d$"#
            isPostalCodeValid = NSPredicate(format: "SELF MATCHES %@", postalCodeRegex).evaluate(with: postalCode)
        }
    }
}
