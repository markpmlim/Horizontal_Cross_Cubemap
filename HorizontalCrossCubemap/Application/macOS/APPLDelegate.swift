//
//  AppDelegate.swift
//  HorizontalCrossCubemap
//
//  Created by Mark Lim Pak Mun on 20/05/2022.
//  Copyright © 2022 mark lim pak mun. All rights reserved.
//

import Cocoa

// Swift need an instance of NSApplicationDelegate
@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {



    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

