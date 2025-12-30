import Foundation
import CoreData

// MARK: - Core Data Stack

class ConversationStore {
    static let shared = ConversationStore()

    private let containerName = "ClaudeCarPlay"

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: containerName)

        // Create model programmatically (no .xcdatamodeld file needed)
        let model = createManagedObjectModel()
        let container2 = NSPersistentContainer(name: containerName, managedObjectModel: model)

        container2.loadPersistentStores { _, error in
            if let error = error {
                print("[CoreData] Failed to load: \(error)")
            }
        }
        return container2
    }()

    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    private func createManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // Message entity
        let messageEntity = NSEntityDescription()
        messageEntity.name = "MessageEntity"
        messageEntity.managedObjectClassName = NSStringFromClass(MessageEntity.self)

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType

        let roleAttr = NSAttributeDescription()
        roleAttr.name = "role"
        roleAttr.attributeType = .stringAttributeType

        let contentAttr = NSAttributeDescription()
        contentAttr.name = "content"
        contentAttr.attributeType = .stringAttributeType

        let timestampAttr = NSAttributeDescription()
        timestampAttr.name = "timestamp"
        timestampAttr.attributeType = .dateAttributeType

        let sessionIdAttr = NSAttributeDescription()
        sessionIdAttr.name = "sessionId"
        sessionIdAttr.attributeType = .stringAttributeType

        messageEntity.properties = [idAttr, roleAttr, contentAttr, timestampAttr, sessionIdAttr]
        model.entities = [messageEntity]

        return model
    }

    // MARK: - Session Management

    private var _sessionId: String?

    var sessionId: String {
        if let existing = _sessionId {
            return existing
        }

        let key = "claude_carplay_session_id"
        if let stored = UserDefaults.standard.string(forKey: key) {
            _sessionId = stored
            return stored
        }

        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: key)
        _sessionId = newId
        return newId
    }

    func newSession() {
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: "claude_carplay_session_id")
        _sessionId = newId
    }

    // MARK: - CRUD

    func saveMessage(role: String, content: String) {
        let message = MessageEntity(context: context)
        message.id = UUID()
        message.role = role
        message.content = content
        message.timestamp = Date()
        message.sessionId = sessionId

        do {
            try context.save()
        } catch {
            print("[CoreData] Save failed: \(error)")
        }
    }

    func loadMessages() -> [[String: Any]] {
        let request = NSFetchRequest<MessageEntity>(entityName: "MessageEntity")
        request.predicate = NSPredicate(format: "sessionId == %@", sessionId)
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]

        do {
            let messages = try context.fetch(request)
            return messages.map { msg in
                [
                    "role": msg.role ?? "user",
                    "content": msg.content ?? ""
                ]
            }
        } catch {
            print("[CoreData] Fetch failed: \(error)")
            return []
        }
    }

    func clearCurrentSession() {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "MessageEntity")
        request.predicate = NSPredicate(format: "sessionId == %@", sessionId)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print("[CoreData] Delete failed: \(error)")
        }
    }

    func messageCount() -> Int {
        let request = NSFetchRequest<MessageEntity>(entityName: "MessageEntity")
        request.predicate = NSPredicate(format: "sessionId == %@", sessionId)
        return (try? context.count(for: request)) ?? 0
    }
}

// MARK: - Core Data Entity

@objc(MessageEntity)
class MessageEntity: NSManagedObject {
    @NSManaged var id: UUID?
    @NSManaged var role: String?
    @NSManaged var content: String?
    @NSManaged var timestamp: Date?
    @NSManaged var sessionId: String?
}
