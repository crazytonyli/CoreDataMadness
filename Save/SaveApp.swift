//
//  SaveApp.swift
//  Save
//
//  Created by Tony Li on 11/01/23.
//

import SwiftUI

@main
struct SaveApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            Text("Hello Core Data")
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
