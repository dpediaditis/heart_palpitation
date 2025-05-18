import Foundation

// MARK: - Questionnaire Models
struct Questionnaire: Codable {
    let resourceType: String
    let title: String
    let language: String
    let status: String
    let meta: Meta
    let useContext: [UseContext]
    let contact: [Contact]
    let subjectType: [String]
    let item: [QuestionnaireItem]
}

struct Meta: Codable {
    let profile: [String]
    let tag: [Tag]
}

struct Tag: Codable {
    let system: String
    let code: String
    let display: String
}

struct UseContext: Codable {
    let code: Code
    let valueCodeableConcept: ValueCodeableConcept
}

struct Code: Codable {
    let system: String
    let code: String
    let display: String
}

struct ValueCodeableConcept: Codable {
    let coding: [Coding]
}

struct Contact: Codable {}

struct QuestionnaireItem: Codable {
    let linkId: String
    let type: String
    let text: String
    let required: Bool?
    let answerOption: [AnswerOption]?
    let extensions: [Extension]?
    let item: [QuestionnaireItem]?
}

struct AnswerOption: Codable {
    let valueCoding: Coding
}

struct Coding: Codable {
    let id: String?
    let system: String
    let code: String?
    let display: String
}

struct Extension: Codable {
    let url: String
    let valueCodeableConcept: ValueCodeableConcept
}

// MARK: - Response Models
struct QuestionnaireResponse {
    let resourceType: String = "QuestionnaireResponse"
    let status: String = "completed"
    let authored: String
    let item: [ResponseItem]
    
    struct ResponseItem {
        let linkId: String
        let text: String?
        let answer: [Answer]
        let item: [ResponseItem]?
    }
    
    struct Answer {
        let valueString: String?
        let valueInteger: Int?
        let valueBoolean: Bool?
        let valueDateTime: String?
        let valueCoding: Coding?
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "resourceType": resourceType,
            "status": status,
            "authored": authored
        ]
        
        dict["item"] = item.map { $0.toDictionary() }
        return dict
    }
}

extension QuestionnaireResponse.ResponseItem {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["linkId": linkId]
        
        if let text = text {
            dict["text"] = text
        }
        
        dict["answer"] = answer.map { $0.toDictionary() }
        
        if let nestedItems = item {
            dict["item"] = nestedItems.map { $0.toDictionary() }
        }
        
        return dict
    }
}

extension QuestionnaireResponse.Answer {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [:]
        
        if let value = valueString {
            dict["valueString"] = value
        }
        if let value = valueInteger {
            dict["valueInteger"] = value
        }
        if let value = valueBoolean {
            dict["valueBoolean"] = value
        }
        if let value = valueDateTime {
            dict["valueDateTime"] = value
        }
        if let value = valueCoding {
            dict["valueCoding"] = [
                "system": value.system,
                "code": value.code,
                "display": value.display
            ]
        }
        
        return dict
    }
} 