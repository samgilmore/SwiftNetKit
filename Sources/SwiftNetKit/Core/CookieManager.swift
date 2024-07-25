//
//  CookieManager.swift
//
//
//  Created by Sam Gilmore on 7/22/24.
//

import Foundation

/// Manages cookies for network requests and responses.
public class CookieManager {
    
    /// Shared instance of CookieManager.
    static let shared = CookieManager()
    
    /// UserDefaults key for saving cookies.
    private static let userDefaultsKey = "SWIFTNETKIT_SAVED_COOKIES"
    
    /// UserDefaults suite name for saving cookies.
    private let userDefaults = UserDefaults(suiteName: "SWIFTNETKIT_COOKIE_SUITE")
    
    /// Flag indicating whether to sync cookies with UserDefaults.
    var syncCookiesWithUserDefaults: Bool = true
    
    /// Private initializer to ensure singleton pattern.
    private init() {
        cleanExpiredCookies()
        syncCookies()
    }
    
    /// Includes cookies in the given URLRequest if `includeCookies` is true.
    ///
    /// - Parameters:
    ///   - urlRequest: The URLRequest to include cookies in.
    ///   - includeCookies: Boolean indicating whether to include cookies.
    func includeCookiesIfNeeded(for urlRequest: inout URLRequest, includeCookies: Bool) {
        if includeCookies {
            // Sync cookies with user defaults
            CookieManager.shared.syncCookies()
            
            // Get cookies for the URL
            let cookies = CookieManager.shared.getCookiesForURL(for: urlRequest.url!)
            
            // Create cookie header
            let cookieHeader = HTTPCookie.requestHeaderFields(with: cookies)
            
            // Merge existing cookies with new cookies if any
            if let existingCookieHeader = urlRequest.allHTTPHeaderFields?[HTTPCookie.requestHeaderFields(with: []).keys.first ?? ""] {
                let mergedCookies = (existingCookieHeader + "; " + (cookieHeader.values.first ?? "")).trimmingCharacters(in: .whitespacesAndNewlines)
                urlRequest.allHTTPHeaderFields?[HTTPCookie.requestHeaderFields(with: []).keys.first ?? ""] = mergedCookies
            } else {
                urlRequest.allHTTPHeaderFields = urlRequest.allHTTPHeaderFields?.merging(cookieHeader) { (existing, new) in
                    return existing + "; " + new
                } ?? cookieHeader
            }
        }
    }
    
    /// Saves cookies from the response if `saveResponseCookies` is true.
    ///
    /// - Parameters:
    ///   - response: The URLResponse from which to save cookies.
    ///   - saveResponseCookies: Boolean indicating whether to save response cookies.
    func saveCookiesIfNeeded(from response: URLResponse?, saveResponseCookies: Bool) {
        guard saveResponseCookies,
              let httpResponse = response as? HTTPURLResponse,
              let url = httpResponse.url else { return }
        
        // Extract Set-Cookie headers
        let setCookieHeaders = httpResponse.allHeaderFields.filter { $0.key as? String == "Set-Cookie" }
        
        // Create cookies from headers
        let cookies = HTTPCookie.cookies(withResponseHeaderFields: setCookieHeaders as! [String: String], for: url)
        
        // Save cookies to session storage
        saveCookiesToSession(cookies)
        
        // Save cookies to user defaults if syncCookiesWithUserDefaults is true
        if syncCookiesWithUserDefaults {
            saveCookiesToUserDefaults(cookies)
        }
    }
    
    /// Retrieves cookies for a given URL.
    ///
    /// - Parameter url: The URL for which to retrieve cookies.
    /// - Returns: An array of HTTPCookie objects.
    func getCookiesForURL(for url: URL) -> [HTTPCookie] {
        return HTTPCookieStorage.shared.cookies(for: url) ?? []
    }
    
    /// Synchronizes cookies between session storage and user defaults.
    func syncCookies() {
        if syncCookiesWithUserDefaults {
            // Sync cookies from user defaults to session storage
            loadCookiesFromUserDefaults()
            
            // Sync cookies from session storage to user defaults
            saveCookiesToUserDefaults(getAllCookiesFromSession())
        }
    }
    
    /// Retrieves all cookies from the session storage.
    ///
    /// - Returns: An array of all HTTPCookie objects in the session storage.
    func getAllCookiesFromSession() -> [HTTPCookie] {
        return HTTPCookieStorage.shared.cookies ?? []
    }
    
    /// Saves cookies to the session storage.
    ///
    /// - Parameter cookies: An array of HTTPCookie objects to save.
    func saveCookiesToSession(_ cookies: [HTTPCookie]) {
        for cookie in cookies {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
    }
    
    /// Saves cookies to user defaults.
    ///
    /// - Parameter cookies: An array of HTTPCookie objects to save.
    func saveCookiesToUserDefaults(_ cookies: [HTTPCookie]) {
        var cookieDataArray: [Data] = []
        for cookie in cookies {
            if let data = try? NSKeyedArchiver.archivedData(withRootObject: cookie.properties ?? [:], requiringSecureCoding: false) {
                cookieDataArray.append(data)
            }
        }
        userDefaults?.set(cookieDataArray, forKey: CookieManager.userDefaultsKey)
    }
    
    /// Loads cookies from user defaults into the session storage.
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
    
    /// Deletes all cookies from the session storage and user defaults.
    func deleteAllCookies() {
        // Delete all cookies from session storage
        HTTPCookieStorage.shared.cookies?.forEach(HTTPCookieStorage.shared.deleteCookie)
        
        // Remove cookies from user defaults if syncCookiesWithUserDefaults is true
        if syncCookiesWithUserDefaults {
            userDefaults?.removeObject(forKey: CookieManager.userDefaultsKey)
        }
    }
    
    /// Deletes expired cookies from the session storage and user defaults.
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
        
        // Save valid cookies back to user defaults
        userDefaults?.set(validCookieDataArray, forKey: CookieManager.userDefaultsKey)
    }
    
    /// Cleans expired cookies from the session storage and user defaults.
    func cleanExpiredCookies() {
        deleteExpiredCookies()
        if syncCookiesWithUserDefaults {
            loadCookiesFromUserDefaults()
        }
    }
}
