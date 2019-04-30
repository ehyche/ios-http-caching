//
//  AppDelegate.swift
//  HTTPCachingSampleApp
//
//  Created by Eric Hyche on 4/4/18.
//  Copyright © 2018 HeirPlay Software. All rights reserved.
//

import UIKit

typealias SessionCompletionBlock = (Data?, URLResponse?, Error?) -> Void

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    public struct URLInfo {
        var name: String
        var url: URL?
    }
    
    typealias HeaderGenerator = () -> String
    
    public struct RequestHeaderInfo {
        var displayName: String
        var headerName: String?
        var headerValue: HeaderGenerator?
    }

    var window: UIWindow?
    var session: URLSession?
    var sessionCache: URLCache?
    var urls = [
        URLInfo(name: "show=default",
                url: URL(string: "https://api.groupon.com/api/mobile/US/deals/smoky-mountain-alpine-coaster?show=default&client_id=2995a613b7f3cec7362d4eb30b0d424f")),
        URLInfo(name: "show=uuid",
                url: URL(string: "https://api.groupon.com/api/mobile/US/deals/smoky-mountain-alpine-coaster?show=uuid&client_id=2995a613b7f3cec7362d4eb30b0d424f")),
        URLInfo(name: "show=options",
                url: URL(string: "https://api.groupon.com/api/mobile/US/deals/smoky-mountain-alpine-coaster?show=options&client_id=2995a613b7f3cec7362d4eb30b0d424f")),
    ]
    var headers = [
        RequestHeaderInfo(displayName: "None", headerName: nil, headerValue: nil),
        RequestHeaderInfo(displayName: "X-Brand (fixed)", headerName: "X-Brand", headerValue: { return "groupon" }),
        RequestHeaderInfo(displayName: "X-Request-Id (changes)", headerName: "X-Request-Id", headerValue: { return UUID().uuidString })
    ]
    var taskMetrics = [URLRequest: URLSessionTaskMetrics]()
    var headerController: ResponseHeaderManipulationController? = nil
    var cacheControlRequestHeaderValue: String? {
        return headerController?.cacheControlRequestHeaderValue
    }
    var cacheControlResponseHeaderValue: String? {
        return headerController?.cacheControlResponseHeaderValue
    }
    private struct TaskResponseInfo {
        var response: URLResponse?
        var error: Error?
        var mutableData: NSMutableData?
    }
    private var taskCompletionBlocks = [Int: SessionCompletionBlock]()
    private var taskInfo = [Int: TaskResponseInfo]()

    public func setCompletion(forTask task: URLSessionTask, completion: @escaping SessionCompletionBlock) {
        taskCompletionBlocks[task.taskIdentifier] = completion
    }

    public func clearCompletion(forTask task: URLSessionTask) {
        taskCompletionBlocks[task.taskIdentifier] = nil
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        sessionCache = URLCache(memoryCapacity: URLCache.shared.memoryCapacity,
                                diskCapacity: URLCache.shared.diskCapacity,
                                diskPath: nil)

        let config = URLSessionConfiguration.default
        config.urlCache = sessionCache

        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)

        let appWindow = UIWindow(frame: UIScreen.main.bounds)
        appWindow.backgroundColor = UIColor(white: 0.0, alpha: 0.0)

        // Set up the request/response controller
        let requestResponseController = RequestResponseController(style: .grouped)
        let requestResponseNavController = UINavigationController(rootViewController: requestResponseController)
        requestResponseNavController.tabBarItem.title = "Request/Response"
        requestResponseNavController.tabBarItem.image = UIImage(named: "first")


        // Set up the cache viewer controller
        let cacheDisplayController = CacheDisplayController(style: .grouped)
        let cacheDisplayNavController = UINavigationController(rootViewController: cacheDisplayController)
        cacheDisplayNavController.tabBarItem.title = "Cache"
        cacheDisplayNavController.tabBarItem.image = UIImage(named: "second")


        // Set up the response header manipulation controller
        let responseHeaderController = ResponseHeaderManipulationController(style: .grouped)
        let responseHeaderNavController = UINavigationController(rootViewController: responseHeaderController)
        responseHeaderNavController.tabBarItem.title = "Change Response Headers"
        responseHeaderNavController.tabBarItem.image = UIImage(named: "first")
        headerController = responseHeaderController

        // Set up the tab bar controller
        let tabBarController = UITabBarController(nibName: nil, bundle: nil)
        tabBarController.viewControllers = [requestResponseNavController, cacheDisplayNavController, responseHeaderNavController]

        appWindow.rootViewController = tabBarController
        appWindow.makeKeyAndVisible()

        window = appWindow

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

extension AppDelegate: URLSessionDataDelegate {

    // MARK: - URLSessionTaskDelegate methods

    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
            } else {
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        } else {
            if challenge.previousFailureCount == 0 {
                // Using NSURLSessionAuthChallengeUseCredential with nil will allow connection to go through
                completionHandler(.useCredential, nil)
            } else {
                // I am not sure why we need this one. Probably, to break the loop in case we failed for some other reason then invalid certificate.
                // In any case, NSURLSessionAuthChallengeCancelAuthenticationChallenge will deny the connection.
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        }
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        guard let request = task.originalRequest else {
            return
        }

        taskMetrics[request] = metrics
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let completionHandler = taskCompletionBlocks[task.taskIdentifier] {
            if let info = taskInfo[task.taskIdentifier] {
                var data: Data? = nil
                if let mutableData = info.mutableData {
                    data = Data(referencing: mutableData)
                }
                completionHandler(data, info.response, error)
            } else {
                completionHandler(nil, nil, error)
            }
        }
    }

    // MARK: - URLSessionDataDelegate methods

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        taskInfo[dataTask.taskIdentifier] = TaskResponseInfo(response: response, error: nil, mutableData: nil)
        completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        if let info = taskInfo[dataTask.taskIdentifier] {
            var mutableData = info.mutableData
            if mutableData == nil {
                mutableData = NSMutableData()
            }
            mutableData?.append(data)
            taskInfo[dataTask.taskIdentifier] = TaskResponseInfo(response: info.response, error: info.error, mutableData: mutableData)
        }
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, willCacheResponse proposedResponse: CachedURLResponse, completionHandler: @escaping (CachedURLResponse?) -> Swift.Void) {
        // Only insert the Cache-Control header if we have one to insert
        guard let cacheControlResponseValue = cacheControlResponseHeaderValue else {
            completionHandler(proposedResponse)
            return
        }

        // Only insert the Cache-Control header if the request allows it
        guard let request = dataTask.originalRequest, localCacheAllowed(inRequest: request) else {
            completionHandler(proposedResponse)
            return
        }

        // Make sure the URLResponse is an HTTPURLResponse
        guard let httpUrlResponse = proposedResponse.response as? HTTPURLResponse,
              var responseHeaders = httpUrlResponse.allHeaderFields as? [String:String],
              let url = httpUrlResponse.url else {
                completionHandler(proposedResponse)
                return
        }

        // Check for cache-control header in a different case
        let defaultCacheControlKey = "Cache-Control"
        let defaultCacheControlKeyLowercase = defaultCacheControlKey.lowercased()
        let cacheControlKey = responseHeaders.keys.first { $0.lowercased() == defaultCacheControlKeyLowercase } ?? defaultCacheControlKey

        responseHeaders[cacheControlKey] = cacheControlResponseValue

        // Create a new HTTPURLResponse
        guard let updatedResponse = HTTPURLResponse(url: url, statusCode: httpUrlResponse.statusCode, httpVersion: "HTTP/1.1", headerFields: responseHeaders) else {
            completionHandler(proposedResponse)
            return
        }

        // Create the new CachedURLResponse
        let updatedCachedResponse = CachedURLResponse(response: updatedResponse, data: proposedResponse.data, userInfo: proposedResponse.userInfo, storagePolicy: proposedResponse.storagePolicy)
        completionHandler(updatedCachedResponse)
    }

    // MARK: - Private methods

    private func localCacheAllowed(inRequest request: URLRequest) -> Bool {
        var allowed = true

        switch request.cachePolicy {
        case .reloadIgnoringLocalCacheData: allowed = false
        case .reloadIgnoringLocalAndRemoteCacheData: allowed = false
        default: break
        }

        return allowed
    }


}


