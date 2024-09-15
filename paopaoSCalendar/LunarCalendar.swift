//
//  LunarCalendar.swift
//  paopaoSCalendar
//
//  Created by Ethan on 4/2/24.
//

import SwiftUI

struct LunarCalendar: View {
    
    @Environment(\.calendar) var calendar
    @Environment(\.presentationMode) var mode
    @State private var weekLabelText: String = "Hello, world3331333!"
    
    @State private var beginYear = -1 //日期启动时的开始年，动态改这个值就可以增加显示年份
    @State private var endYear = 1 //日期启动时的结束年，动态改这个值就可以增加显示年份
    
    /**
     获取今年的时间间隔用于展示日历，需要修改
     */
    private var currentyear: DateInterval {
        calendar.dateInterval(of: .year, for: Date())!
    }
    //改成获取最近10年的时间间隔
    private var lastTenYears: DateInterval {
        let currentDate = Date()
        let calendar = Calendar.current
        let tenYearsAgo = calendar.date(byAdding: .year, value: beginYear, to: currentDate)!
        let tenYearsLater = calendar.date(byAdding: .year, value: endYear, to: currentDate)!
        return DateInterval(start: tenYearsAgo, end: tenYearsLater)
    }
    
    private let onSelect: (Date) -> Void
    
    public init(select: @escaping (Date) -> Void) {
      self.onSelect = select
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 0, content: {
            Button(action: { // 添加新行按钮
                beginYear = -10
                endYear = 10
            }) {
                Text("添加新行")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            
            Text(String(weekLabelText))
            HStack{
                ForEach(1...7, id: \.self) { count in
                    Text(Tool.getWeek(week: count))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
            }.background(Color.brown)
            
            //这里初始化日历启动时显示的时间范围
            CalendarGrid(interval: lastTenYears,weekLabelText: $weekLabelText) { date in
                CalenderDay(day: Tool.getDay(date: date),
                            lunar: Tool.getInfo(date: date),
                            isToday: calendar.isDateInToday(date),
                            isWeekDay: Tool.isWeekDay(date: date))
                    .onTapGesture {//点击视图的事件
                        mode.wrappedValue.dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            self.onSelect(date)
                            print("Clicked date: \(date)") // 打印点击的日期
                        }
                    }
            }
        })
        .padding([.leading, .trailing], 10.0)
    }
}
/*
 日历网格
 */
public struct CalendarGrid<DateView>: View where DateView: View {
    @Environment(\.calendar) var calendar
    
    @State private var scrollProxy: ScrollViewProxy?
    @State private var gridHeight: CGFloat = 0   //网格高度
    @State private var gridHeighttemp2: CGFloat = 0   //网格高度
    
    @State private var visibleSectionID: Int? = nil//根据chatgpt加的获取当前屏幕显示的月份的sectionID用的
    
    //@State private var labelText : String = "Hello, World2233!"
    
    let interval: DateInterval   //时间间隔
    let showHeaders: Bool      //是否显示每月的title
    let content: (Date) -> DateView
    
    @Binding var weekLabelText: String
    @State private var isLoading: Bool = false
    //let log=OSLog(subsystem: "com.paopaobox.calendar", category: "YourCategory")
    
    public init(interval: DateInterval, showHeaders: Bool = true,weekLabelText: Binding<String>, @ViewBuilder content: @escaping (Date) -> DateView) {
        self.interval = interval
        self.showHeaders = showHeaders
        self.content = content
        self._weekLabelText = weekLabelText
    }
    
    public var body: some View {

        ///添加到可以滚动
        ScrollView(.vertical, showsIndicators: false){
            ///添加滚动监听
            ScrollViewReader { (proxy: ScrollViewProxy) in
                ///生成网格
                LazyVGrid(columns: Array(repeating: GridItem(spacing: 2, alignment: .center), count: 7)) {
                    ///枚举每个月
                    ForEach(arrayMonths, id: \.self) { month in
                        ///以每月为一个Section,添加月份
                        Section(header: getHeader(for: month)) {
                            ///添加日
                            //var loopCount = 0 // 定义一个计数器
                            ForEach(getDays(for: month), id: \.self) { date in
                                ///如果不在当月就隐藏
                                if calendar.isDate(date, equalTo: month, toGranularity: .month) {
                                    content(date).id(date)
                                    
                                } else {
                                    content(date).hidden()//每个月初和月末的空的空格子
                                }
                            }
                        }
                        .id(getYearMonthSectionID(for: month))//修改成用年和月做SectionID，做这个id标记是给自动滚动到今天或者判断滚动到什么位置了使用
                        //let _ = print("getYearMonthSectionID====\(getYearMonthSectionID(for: month))")
                        .gesture(
                            DragGesture(minimumDistance: 10)
                                .onChanged { value in
                                    //draggedMonthIndex = monthIndex
                                    //updateCurrentYearAndMonth(with: value)
                                    print("aaaa")
                                }
                                .onEnded { _ in
                                    //draggedMonthIndex = nil
                                    print("bbb")
                                }
                        )
                        .background(
                            GeometryReader { geometry in
                                Color.clear.preference(key: SectionIDPreferenceKey.self, value: getYearMonthSectionID(for: month))
                            }
                        )
                    }
                }
                .onPreferenceChange(SectionIDPreferenceKey.self) { value in
                    visibleSectionID = value    //visibleSectionID 里是年和月 格式是 202409
                    //print("Visible Section ID: \(visibleSectionID ?? -1)")
                    
                    if let visibleSectionIDtemp = visibleSectionID {
                        var year = visibleSectionIDtemp / 100 // 假设整数部分代表年份
                        var month = visibleSectionIDtemp % 100 // 假设百位数代表月份
                        //print("Visible Section Year: \(year), Month: \(month)")
                        if month != 12 {
                            month += 1 // 如果不等于 12，则加 1
                        } else {
                            year += 1
                            month = 1 // 如果等于 12，则设置为 1
                        }
                        //weekLabelText = "\(year)年\(month)月"
                        //weekLabelText = "\(year)年"
                        //updateWeekLabelText(with: "\(year)年\(month)月") //每月更新title显示
                        updateWeekLabelText(with: "\(year)年")//每年更新title显示
                    } else {
                        print("Visible Section ID is nil.")
                    }
                }
                .onAppear(){
                    ///当View展示的时候直接滚动到标记好的月份
                    print("当View展示的时候直接滚动到标记好的月份")
                    //os_log("test",log: log,type: .debug)
                    proxy.scrollTo(getYearMonthScroolSectionID() )
                }
               // Text("LazyVGrid Height: \(gridHeight)")
                //Text("LazyVGrid gridHeighttemp2: \(gridHeighttemp2)")
            }
        }
    }

    public func updateWeekLabelText(with newText: String) {
        // 显示加载提示
        self.isLoading = true
        // 在后台线程中执行异步任务
        DispatchQueue.global().async {
            // 模拟数据加载过程
            // 假设这里是您实际的数据加载逻辑
            // 例如从网络请求数据等
            Thread.sleep(forTimeInterval: 0.1)
            // 返回主线程更新 UI
            DispatchQueue.main.async {
                // 更新数据
                // 使用 withAnimation 修饰符包装界面更新操作
                withAnimation {
                    self.weekLabelText = newText
                    self.isLoading = false
                }
            }
        }
    }

    ///获取当前是几年几月,并进行滚动到那里
    private func getYearMonthScroolSectionID() -> Int {
        var year = calendar.component(.year, from: Date())
        var month = calendar.component(.month, from: Date())
        //year=2025
        //month=1
        
        if month != 12 {
            month += 1 // 如果不等于 12，则加 1
        } else {
            year += 1
            month = 1 // 如果等于 12，则设置为 1
        }
        print("当前GMT格林尼治标准时间日期是：\(Date())")
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.timeZone = TimeZone.current // 使用当前时区

        let localDate = dateFormatter.string(from: Date())
        print("当前本地日期是：\(localDate)")
        // 将年和月组合成一个唯一的整数作为滚动标记的 section ID
        let sectionID = year * 100 + month
        print("getYearMonthScroolSectionID====\(sectionID)")
        return sectionID
    }
    
    /// 根据年月生成 Section ID
    private func getYearMonthSectionID(for date: Date) -> Int {
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        
        // 将年和月组合成一个唯一的整数作为 Section ID
        let sectionID = year * 100 + month
       // print("sectionID====\(sectionID)")
        return sectionID
    }
    
    ///获得年间距的月份日期的第一天,生成数组
    private var arrayMonths: [Date] {
        calendar.getGenerateDates(
            inside: interval,
            matching: DateComponents(day: 1, hour: 0, minute: 0, second: 0)
        )
    }
    
    ///创建一个简单的SectionHeader
    private func getHeader(for month: Date) -> some View {
        let component = calendar.component(.month, from: month)
        let formatter = component == 1 ? DateFormatter.getDFmonthAndYear : .getDFmonth
        
        return Group {
            if showHeaders {
                Text(formatter.string(from: month))
                    .font(.title)
                    .padding()
            }
        }
    }
    
    ///获取每个月,网格范围内的起始结束日期数组
    private func getDays(for month: Date) -> [Date] {
        ///重点讲解
        ///先拿到月份间距,例如1号--31号
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else { return [] }
        ///先获取第一天所在周的周一到周日
        let monthFirstWeek = monthInterval.start.getWeekStartAndEnd(isEnd: false)
        ///获取月最后一天所在周的周一到周日
        let monthLastWeek = monthInterval.end.getWeekStartAndEnd(isEnd: true)
        ///然后根据月初所在周的周一为0号row 到月末所在周的周日为最后一个row生成数组
        return calendar.getGenerateDates(
            inside: DateInterval(start: monthFirstWeek.start, end: monthLastWeek.end),
            matching: DateComponents(hour: 0, minute: 0, second: 0)
        )
    }

}

/*
 日历网格里的每一天
 */
struct CalenderDay: View {
    let day: String
    let lunar: String
    let isToday: Bool
    let isWeekDay: Bool
    
    var body: some View {
        ZStack{
            VStack{
                
                Text(day)
                    .frame(width: 40, height: 40, alignment: .center)
                    .font(.title)
                    .foregroundColor(isWeekDay ? Color.red : Color.gray)
                
                Text(lunar)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: true, vertical: false)
                    .foregroundColor(isWeekDay ? Color.red : Color.gray)
            }
            .padding(.bottom, 5.0)
            .overlay(
                RoundedRectangle(cornerRadius: 5).stroke( isToday ? Color.orange : Color.clear, lineWidth: 2)
            )
        }
    }
}

//根据chatgpt加的获取当前屏幕显示的月份的sectionID用的
struct SectionIDPreferenceKey: PreferenceKey {
    static var defaultValue: Int? = nil
    static func reduce(value: inout Int?, nextValue: () -> Int?) {
        value = value ?? nextValue()
    }
}

extension Date {
    func getWeekDay() -> Int{
        let calendar = Calendar.current
        ///拿到现在的week数字
        let components = calendar.dateComponents([.weekday], from: self)
        return components.weekday!
    }
    
    ///获取当前Date所在周的周一到周日
    func getWeekStartAndEnd(isEnd: Bool) -> DateInterval{
        var date = self
        ///因为一周的起始日是周日,周日已经算是下一周了
        ///如果是周日就到退回去两天
        if isEnd {
            if date.getWeekDay() <= 2 {
                date = date.addingTimeInterval(-60 * 60 * 24 * 2)
            }
        }else{
            if date.getWeekDay() == 1 {
                date = date.addingTimeInterval(-60 * 60 * 24 * 2)
            }
        }
        ///使用处理后的日期拿到这一周的间距: 周日到周六
        let week = Calendar.current.dateInterval(of: .weekOfMonth, for: date)!
        ///处理一下周日加一天到周一
        let monday = week.start.addingTimeInterval(60 * 60 * 24)
        ///周六加一天到周日
        let sunday = week.end.addingTimeInterval(60 * 60 * 24)
        ///生成新的周一到周日的间距
        let interval = DateInterval(start: monday, end: sunday)
        return interval
    }
}

extension DateFormatter {
    static var getDFmonth: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月"
        return formatter
    }
    
    static var getDFmonthAndYear: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }
}

extension Calendar {
    func getGenerateDates(inside interval: DateInterval, matching components: DateComponents) -> [Date] {
        var dates: [Date] = []
        dates.append(interval.start)
        enumerateDates(startingAfter: interval.start, matching: components, matchingPolicy: .nextTime) { date, _, stop in
            if let date = date {
                if date < interval.end {
                    dates.append(date)
                } else {
                    stop = true
                }
            }
        }
        return dates
    }
}

struct Tool {
    static func getWeek(week: Int) -> String{
        switch week {
        case 1:
            return "周一"
        case 2:
            return "周二"
        case 3:
            return "周三"
        case 4:
            return "周四"
        case 5:
            return "周五"
        case 6:
            return "周六"
        case 7:
            return "周日"
        default:
            return ""
        }
    }

    static let chineseHoliDay:[String:String] = ["1-1":"春节",
                                                 "1-15":"元宵节",
                                                 "2-2":"龙抬头",
                                                 "5-5":"端午",
                                                 "7-7":"七夕",
                                                 "7-15":"中元",
                                                 "8-15":"中秋",
                                                 "9-9":"重阳",
                                                 "12-8":"腊八",
                                                 "12-23":"小年(北)",
                                                 "12-24":"小年(南)",
                                                 "12-30":"除夕"]
    
    static let gregorianHoliDay:[String:String] = ["1-1":"元旦",
                                                   "2-14":"情人节",
                                                   "3-8":"妇女节",
                                                   "3-12":"植树节",
                                                   "4-4":"清明",
                                                   "5-1":"劳动节",
                                                   "5-4":"青年节",
                                                   "6-1":"儿童节",
                                                   "7-1":"建党节",
                                                   "8-1":"建军节",
                                                   "10-1":"国庆",
                                                   "12-24":"平安夜",
                                                   "12-25":"圣诞节"]
    
    ///得到参数date的日期
    static func getDay(date: Date) -> String{
        return String(Calendar.current.component(.day, from: date))
    }
    
    ///获取农历, 节假日名
    static func getInfo(date: Date) -> String{
        //初始化农历日历
        let lunarCalendar = Calendar.init(identifier: .chinese)
        
        ///获得农历月
        let lunarMonth = DateFormatter()
        lunarMonth.locale = Locale(identifier: "zh_CN")
        lunarMonth.dateStyle = .medium
        lunarMonth.calendar = lunarCalendar
        lunarMonth.dateFormat = "MMM"
        
        let month = lunarMonth.string(from: date)
        
        //获得农历日
        let lunarDay = DateFormatter()
        lunarDay.locale = Locale(identifier: "zh_CN")
        lunarDay.dateStyle = .medium
        lunarDay.calendar = lunarCalendar
        lunarDay.dateFormat = "d"
        
        let day = lunarDay.string(from: date)
        ///生成公历日历的Key 用于查询字典
        let gregorianFormatter = DateFormatter()
        gregorianFormatter.locale = Locale(identifier: "zh_CN")
        gregorianFormatter.dateFormat = "M-d"
        
        let gregorian = gregorianFormatter.string(from: date)
        
        ///生成农历的key
        let lunarFormatter = DateFormatter()
        lunarFormatter.locale = Locale(identifier: "zh_CN")
        lunarFormatter.dateStyle = .short
        lunarFormatter.calendar = lunarCalendar
        lunarFormatter.dateFormat = "M-d"
        
        let lunar = lunarFormatter.string(from: date)
        
        ///如果是节假日返回节假日名称
        if let holiday = getHoliday(lunarKey: lunar, gregorKey: gregorian) {
            return holiday
        }
        
        //返回农历月
        if day == "初一" {
            return month
        }
        
        //返回农历日期
        return day
        
    }
    
    static func getHoliday(lunarKey: String, gregorKey: String) -> String?{
        
        ///当前农历节日优先返回
        if let holiday = chineseHoliDay[lunarKey]{
            return holiday
        }
        
        ///当前公历历节日返回
        if let holiday = gregorianHoliDay[gregorKey]{
            return holiday
        }
        
        return nil
    }
    
    static func isWeekDay(date: Date) -> Bool{
        switch date.getWeekDay() {
        case 7, 1:
            return true
        default:
            return false
        }
    }
    
}
