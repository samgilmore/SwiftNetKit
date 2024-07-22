//
//  NetworkService+Cookies.swift
//
//
//  Created by Sam Gilmore on 7/22/24.
//

import Foundation

extension NetworkService {
    func getAllCookies() -> [HTTPCookie] {
        return HTTPCookieStorage.shared.cookies ?? []
    }
    
    func getCookiesForURL(for url: URL) -> [HTTPCookie] {
        HTTPCookieStorage.shared.cookies(for: url) ?? []
    }
    
    func removeCookies(matching criteria: [HTTPCookiePropertyKey: String]) {
        let cookies = HTTPCookieStorage.shared.cookies ?? []
        for cookie in cookies {
            var match = true
            for (key, value) in criteria {
                if cookie.properties?[key] as? String != value {
                    match = false
                    break
                }
            }
            if match {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
    }
    
    func resetCookies() {
        let cookies = HTTPCookieStorage.shared.cookies ?? []
        for cookie in cookies {
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
    }
    
    func saveCookiesToSession(_ cookies: [HTTPCookie], for url: URL) {
        HTTPCookieStorage.shared.setCookies(cookies, for: url, mainDocumentURL: nil)
    }
    
    func saveCookiesToUserDefaults(_ cookies: [HTTPCookie]) {
        let cookieData = cookies.compactMap { try? NSKeyedArchiver.archivedData(withRootObject: $0.properties ?? [:], requiringSecureCoding: false) }
        UserDefaults.standard.set(cookieData, forKey: "savedCookies")
    }
    
    func loadCookiesFromUserDefaults() {
        guard let cookieDataArray = UserDefaults.standard.array(forKey: "savedCookies") as? [Data] else {
            return
        }
        
        let allowedClasses: [AnyClass] = [NSDictionary.self, NSString.self, NSDate.self, NSNumber.self, NSURL.self]
        
        for cookieData in cookieDataArray {
            if let cookieProperties = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: allowedClasses, from: cookieData) as? [HTTPCookiePropertyKey: Any],
               let cookie = HTTPCookie(properties: cookieProperties) {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
    }
    
    func removeExpiredCookies() {
        let cookies = HTTPCookieStorage.shared.cookies ?? []
        let now = Date()
        for cookie in cookies {
            if let expiresDate = cookie.expiresDate, expiresDate <= now {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
    }
}
