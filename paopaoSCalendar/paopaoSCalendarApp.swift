//
//  paopaoSCalendarApp.swift
//  paopaoSCalendar
//
//  Created by Ethan on 4/2/24.
//

import SwiftUI

@main
struct paopaoSCalendarApp: App {
    var body: some Scene {
        WindowGroup {
            LunarCalendar(select: { date in
                print("这里返回的居然是用户点击的日期的时间,好像目前没什么用==\(date)")
            })
        }
    }
}
