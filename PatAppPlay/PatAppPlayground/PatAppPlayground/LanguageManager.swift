import Foundation

enum AppLanguage: String {
    case english = "en"
    case swedish = "sv"
}

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    @Published var currentLanguage: AppLanguage = .english
    
    private init() {}
    
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }
    
    func localizedString(_ key: String) -> String {
        switch currentLanguage {
        case .english:
            return englishStrings[key] ?? key
        case .swedish:
            return swedishStrings[key] ?? key
        }
    }
    
    private let englishStrings: [String: String] = [
        // Login View
        "app_name": "PatApp Playground",
        "secure_health_data": "Secure Health Data Sharing",
        "login_with_bankid": "Login with BankID",
        "authentication_failed": "BankID authentication failed. Please try again.",
        "select_language": "Select Language",
        "english": "English",
        "swedish": "Swedish",
        
        // Main Content View
        "share_health_data": "Share Health Data",
        "data_types_to_share": "Data Types to Share",
        "select_data_types": "Select Data Types",
        "select_time_window": "Select Time Window",
        "start_date": "Start Date",
        "end_date": "End Date",
        "share_with_bankid": "Share with BankID Consent",
        "consent_authorized": "Consent Authorized",
        "consent_saved": "Your consent has been saved.",
        "ok": "OK",
        "share": "Share",
        "consent_log": "Consent Log",
        "services": "Services",
        
        // Consent Log View
        "shared_data": "Shared Data",
        "time_period": "Time Period",
        "from": "From",
        "to": "To",
        "status": "Status",
        "active": "Active",
        "expired": "Expired",
        "bankid_tx": "BankID TX",
        "export_data": "Export Data",
        "withdraw_consent": "Withdraw Consent",
        "withdraw_confirm": "Are you sure you want to withdraw this active consent? This action cannot be undone.",
        "withdraw": "Withdraw",
        "cancel": "Cancel",
        "export_error": "Export Error",
        
        // Data Type Selection View
        "activity_data": "Activity Data",
        "heart_health": "Heart Health",
        "energy_fitness": "Energy & Fitness",
        "heart_rate_recovery": "Heart Rate Recovery",
        "other_health_data": "Other Health Data",
        "done": "Done",
        "data_source": "Data Source",
        "collected_from_watch": "Collected from Apple Watch",
        "collected_from_phone": "Collected from iPhone or manually entered",
        "collected_from_both": "Collected from both Apple Watch and iPhone",
        "manually_entered": "Manually entered data",
        "close": "Close",
        
        // Condition Services View
        "available_services": "Available Services",
        "heart_palpitation": "Heart Palpitation",
        "open_fibricheck": "Open FibriCheck",
        "fibricheck_confirm": "This will open the FibriCheck app to help you monitor your heart palpitations. Would you like to proceed?",
        "open": "Open",
        "sharedDataTitle": "Shared Health Data",
        "noActiveConsent": "No active consent found. Please give consent to view shared data.",
        "samples": "samples",
        "lastUpdated": "Last updated"
    ]
    
    private let swedishStrings: [String: String] = [
        // Login View
        "app_name": "PatApp Spelplan",
        "secure_health_data": "Säker Delning av Hälsodata",
        "login_with_bankid": "Logga in med BankID",
        "authentication_failed": "BankID-autentisering misslyckades. Vänligen försök igen.",
        "select_language": "Välj Språk",
        "english": "Engelska",
        "swedish": "Svenska",
        
        // Main Content View
        "share_health_data": "Dela Hälsodata",
        "data_types_to_share": "Datatyper att Dela",
        "select_data_types": "Välj Datatyper",
        "select_time_window": "Välj Tidsperiod",
        "start_date": "Startdatum",
        "end_date": "Slutdatum",
        "share_with_bankid": "Dela med BankID Godkännande",
        "consent_authorized": "Godkännande Beviljat",
        "consent_saved": "Ditt godkännande har sparats.",
        "ok": "OK",
        "share": "Dela",
        "consent_log": "Godkännandelogg",
        "services": "Tjänster",
        
        // Consent Log View
        "shared_data": "Delad Data",
        "time_period": "Tidsperiod",
        "from": "Från",
        "to": "Till",
        "status": "Status",
        "active": "Aktiv",
        "expired": "Utgången",
        "bankid_tx": "BankID Transaktion",
        "export_data": "Exportera Data",
        "withdraw_consent": "Återkalla Godkännande",
        "withdraw_confirm": "Är du säker på att du vill återkalla detta aktiva godkännande? Denna åtgärd kan inte ångras.",
        "withdraw": "Återkalla",
        "cancel": "Avbryt",
        "export_error": "Exportfel",
        
        // Data Type Selection View
        "activity_data": "Aktivitetsdata",
        "heart_health": "Hjärthälsa",
        "energy_fitness": "Energi & Fitness",
        "heart_rate_recovery": "Hjärtfrekvensåterhämtning",
        "other_health_data": "Övrig Hälsodata",
        "done": "Klar",
        "data_source": "Datakälla",
        "collected_from_watch": "Samlas in från Apple Watch",
        "collected_from_phone": "Samlas in från iPhone eller matas in manuellt",
        "collected_from_both": "Samlas in från både Apple Watch och iPhone",
        "manually_entered": "Manuellt inmatad data",
        "close": "Stäng",
        
        // Condition Services View
        "available_services": "Tillgängliga Tjänster",
        "heart_palpitation": "Hjärtklappning",
        "open_fibricheck": "Öppna FibriCheck",
        "fibricheck_confirm": "Detta kommer att öppna FibriCheck-appen för att hjälpa dig att övervaka din hjärtklappning. Vill du fortsätta?",
        "open": "Öppna",
        "sharedDataTitle": "Delade Hälsodata",
        "noActiveConsent": "Inget aktivt samtycke hittades. Vänligen ge samtycke för att visa delade data.",
        "samples": "prover",
        "lastUpdated": "Senast uppdaterad"
    ]
} 