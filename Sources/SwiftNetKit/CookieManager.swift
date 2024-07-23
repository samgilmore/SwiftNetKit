//
//  CookieManager.swift
//
//
//  Created by Sam Gilmore on 7/22/24.
//

import Foundation

class CookieManager {
    static let shared = CookieManager()
    
    private static let userDefaultsKey = "SWIFTNETKIT_SAVED_COOKIES"
    private let userDefaults = UserDefaults(suiteName: "SWIFTNETKIT_COOKIE_SUITE")
    
    var syncCookiesWithUserDefaults: Bool = true
    
    private init() {
        cleanExpiredCookies()
        syncCookies()
    }
    
    func includeCookiesIfNeeded(for urlRequest: inout URLRequest, includeCookies: Bool) {
        if includeCookies {
            CookieManager.shared.syncCookies()
            let cookies = CookieManager.shared.getCookiesForURL(for: urlRequest.url!)
            let cookieHeader = HTTPCookie.requestHeaderFields(with: cookies)
            
            urlRequest.allHTTPHeaderFields = urlRequest.allHTTPHeaderFields?.merging(cookieHeader) { (_, new) in new } ?? cookieHeader
        }
    }
    
    func saveCookiesIfNeeded(from response: URLResponse?, saveResponseCookies: Bool) {
        guard saveResponseCookies,
              let httpResponse = response as? HTTPURLResponse,
              let url = httpResponse.url else { return }
        
        let setCookieHeaders = httpResponse.allHeaderFields.filter { $0.key as? String == "Set-Cookie" }
        
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: setCookieHeaders as! [String: String], for: url)
        
        saveCookiesToSession(cookies, for: url)
        
        if syncCookiesWithUserDefaults {
            saveCookiesToUserDefaults(cookies)
        }
    }
    
    func getCookiesForURL(for url: URL) -> [HTTPCookie] {
        return HTTPCookieStorage.shared.cookies(for: url) ?? []
    }
    
    func syncCookies() {
        if syncCookiesWithUserDefaults {
            // Sync cookies from user defaults to session storage
            loadCookiesFromUserDefaults()
            
            // Sync cookies from session storage to user defaults
            saveCookiesToUserDefaults(getAllCookiesFromSession())
        }
    }
    
    func getAllCookiesFromSession() -> [HTTPCookie] {
        return HTTPCookieStorage.shared.cookies ?? []
    }
    
    func saveCookiesToSession(_ cookies: [HTTPCookie], for url: URL) {
        for cookie in cookies {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
    }
    
    func saveCookiesToUserDefaults(_ cookies: [HTTPCookie]) {
        var cookieDataArray: [Data] = []
        for cookie in cookies {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: cookie.properties ?? [:], requiringSecureCoding: false) {
                cookieDataArray.append(data)
            }
        }
        userDefaults?.set(cookieDataArray, forKey: CookieManager.userDefaultsKey)
    }
    
    func loadCookiesFromUserDefaults() {
        guard let cookieDataArray = userDefaults?.array(forKey: CookieManager.userDefaultsKey) as? [Data] else { return }
        
        let allowedClasses: [AnyClass] = [NSDictionary.self, NSString.self, NSDate.self, NSNumber.self, NSURL.self]
        
        for cookieData in cookieDataArray {
            if let cookieProperties = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: allowedClasses, from: cookieData) as? [HTTPCookiePropertyKey: Any],
               let cookie = HTTPCookie(properties: cookieProperties) {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
    }
    
    func deleteAllCookies() {
        HTTPCookieStorage.shared.cookies?.forEach(HTTPCookieStorage.shared.deleteCookie)
        if syncCookiesWithUserDefaults {
            userDefaults?.removeObject(forKey: CookieManager.userDefaultsKey)
        }
    }
    
    func deleteExpiredCookies() {
        guard let cookieDataArray = userDefaults?.array(forKey: CookieManager.userDefaultsKey) as? [Data] else { return }
        var validCookieDataArray: [Data] = []
        
        let allowedClasses: [AnyClass] = [NSDictionary.self, NSString.self, NSDate.self, NSNumber.self, NSURL.self]
        
        for cookieData in cookieDataArray {
            if let cookieProperties = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: allowedClasses, from: cookieData) as? [HTTPCookiePropertyKey: Any],
               let cookie = HTTPCookie(properties: cookieProperties),
               cookie.expiresDate ?? Date.distantFuture > Date() {
                validCookieDataArray.append(cookieData)
            }
        }
        
        userDefaults?.set(validCookieDataArray, forKey: CookieManager.userDefaultsKey)
    }
    
    func cleanExpiredCookies() {
        deleteExpiredCookies()
        if syncCookiesWithUserDefaults {
            loadCookiesFromUserDefaults()
        }
    }
}
