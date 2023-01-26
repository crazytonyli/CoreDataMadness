//
//  Persistence.swift
//  Save
//
//  Created by Tony Li on 11/01/23.
//

import CoreData

class UserService {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer) {
        self.container = container
    }

    func createUser(name: String) -> NSManagedObjectID {
        var id: NSManagedObjectID! = nil
        let context = container.newBackgroundContext()
        context.performAndWait {
            let user = User(context: context)
            user.name = name
            try! context.save()

            id = user.objectID
        }
        return id
    }

    func updateUser(id: NSManagedObjectID, name: String) {
        let context = container.newBackgroundContext()

        context.performAndWait {
            let user = try! context.existingObject(with: id) as! User
            user.name = name
            try! context.save()
        }
    }

    func deleteUser(id: NSManagedObjectID) {
        let context = container.newBackgroundContext()

        context.performAndWait {
            let user = try! context.existingObject(with: id) as! User
            context.delete(user)
            try! context.save()
        }
    }
}

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Save")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true

        let service = UserService(container: container)
        testDelete(service)
    }

    func testDelete(_ service: UserService) {
        let userID = service.createUser(name: "Foo")
        let userInViewContext = try! container.viewContext.existingObject(with: userID) as! User
        assert(userInViewContext.name == "Foo")

        service.deleteUser(id: userID)

        let performCheck: (String) -> Void = { label in
            print("[\(#function)] CHECK \(label): isDeleted == true? \(userInViewContext.isDeleted ? "✅" : "❌")")
            print("[\(#function)] CHECK \(label): existingObject(with: userID) == nil? \((try? container.viewContext.existingObject(with: userID)) == nil ? "✅" : "❌")")
            print("")
        }

        // ❓ CHECK 1
        print("Immediately after the deletion")
        performCheck("1")

        // ❓ CHECK 1.1
        container.viewContext.refreshAllObjects()
        print("After `refreshAllObjects`")
        performCheck("1.1")

        // But eventually, we can see the `user` in `viewContext` is updated.

        // ❓ CHECK 2
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
            print("1 second later in the main thread")
            performCheck("2")
        }

        // ❓ CHECK 3
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            print("Another second later in the main thread")
            performCheck("3")
        }

        // ❓ CHECK 4
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3)) {
            print("Another second later in the main thread")
            print("And, let's `refreshAllObjects` again")
            container.viewContext.refreshAllObjects()
            performCheck("4")
        }
    }
}
