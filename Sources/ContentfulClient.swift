//
//  ContentfulClient.swift
//  Contentful
//
//  Created by Boris Bügling on 18/08/15.
//  Copyright © 2015 Contentful GmbH. All rights reserved.
//

import Clock
import Decodable
import Foundation
import Interstellar

/// Client object for performing requests against the Contentful API
public class ContentfulClient {
    private let configuration: Configuration
    private let network = Network()
    private let spaceIdentifier: String

    private var scheme: String { return configuration.secure ? "https" : "http" }

    /**
     Initializes a new Contentful client instance

     - parameter spaceIdentifier: The space you want to perform requests against
     - parameter accessToken:     The access token used for authorization
     - parameter configuration:   Custom configuration of the client

     - returns: An initialized client instance
     */
    public init(spaceIdentifier: String, accessToken: String, configuration: Configuration = Configuration()) {
        network.sessionConfigurator = { (sessionConfiguration) in
            sessionConfiguration.HTTPAdditionalHeaders = [ "Authorization": "Bearer \(accessToken)" ]
        }

        self.configuration = configuration
        self.spaceIdentifier = spaceIdentifier
    }

    private func fetch<T: Decodable>(url: NSURL?, _ completion: Result<T> -> Void) -> NSURLSessionDataTask? {
        if let url = url {
            let (task, signal) = network.fetch(url)

            signal.next { (data) in
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                    completion(.Success(try T.decode(json)))
                } catch let error as DecodingError {
                    completion(.Error(ContentfulError.UnparseableJSON(data: data, errorMessage: error.debugDescription)))
                } catch _ {
                    completion(.Error(ContentfulError.UnparseableJSON(data: data, errorMessage: "")))
                }
            }.error { completion(.Error($0)) }

            return task
        }

        completion(.Error(ContentfulError.InvalidURL(string: "")))
        return nil
    }

    private func URLForFragment(fragment: String = "", parameters: [String: AnyObject]? = nil) -> NSURL? {
        if let components = NSURLComponents(string: "\(scheme)://\(configuration.server)/spaces/\(spaceIdentifier)/\(fragment)") {
            if let parameters = parameters {
                let queryItems: [NSURLQueryItem] = parameters.map() { (key, var value) in
                    if let date = value as? NSDate, dateString = date.toISO8601GMTString() {
                        value = dateString
                    }

                    if let array = value as? NSArray {
                        value = array.componentsJoinedByString(",")
                    }

                    return NSURLQueryItem(name: key, value: value.description)
                }

                if queryItems.count > 0 {
                    components.queryItems = queryItems
                }
            }

            if let url = components.URL {
                return url
            }
        }
        
        return nil
    }
}

extension ContentfulClient {
    /**
     Fetch a single Asset from Contentful

     - parameter identifier: The identifier of the Asset to be fetched
     - parameter completion: A handler being called on completion of the request

     - returns: The data task being used, enables cancellation of requests
     */
    public func fetchAsset(identifier: String, completion: Result<Asset> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("assets/\(identifier)"), completion)
    }

    /**
     Fetch a single Asset from Contentful

     - parameter identifier: The identifier of the Asset to be fetched

     - returns: A tuple of data task and a signal for the resulting Asset
     */
    public func fetchAsset(identifier: String) -> (NSURLSessionDataTask?, Signal<Asset>) {
        return signalify(identifier, fetchAsset)
    }

    /**
     Fetch a collection of Assets from Contentful

     - parameter matching:   Optional list of search parameters the Assets must match
     - parameter completion: A handler being called on completion of the request

     - returns: The data task being used, enables cancellation of requests
     */
    public func fetchAssets(matching: [String:AnyObject] = [String:AnyObject](), completion: Result<ContentfulArray<Asset>> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("assets", parameters: matching), completion)
    }

    /**
     Fetch a collection of Assets from Contentful

     - parameter matching: Optional list of search parameters the Assets must match

     - returns: A tuple of data task and a signal for the resulting array of Assets
     */
    public func fetchAssets(matching: [String:AnyObject] = [String:AnyObject]()) -> (NSURLSessionDataTask?, Signal<ContentfulArray<Asset>>) {
        return signalify(matching, fetchAssets)
    }
}

extension ContentfulClient {
    /**
     Fetch a single Content Type from Contentful

     - parameter identifier: The identifier of the Content Type to be fetched
     - parameter completion: A handler being called on completion of the request

     - returns: The data task being used, enables cancellation of requests
     */
    public func fetchContentType(identifier: String, completion: Result<ContentType> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("content_types/\(identifier)"), completion)
    }

    /**
     Fetch a single Content Type from Contentful

     - parameter identifier: The identifier of the Content Type to be fetched

     - returns: A tuple of data task and a signal for the resulting Content Type
     */
    public func fetchContentType(identifier: String) -> (NSURLSessionDataTask?, Signal<ContentType>) {
        return signalify(identifier, fetchContentType)
    }

    /**
     Fetch a collection of Content Types from Contentful

     - parameter matching:   Optional list of search parameters the Content Types must match
     - parameter completion: A handler being called on completion of the request

     - returns: The data task being used, enables cancellation of requests
     */
    public func fetchContentTypes(matching: [String:AnyObject] = [String:AnyObject](), completion: Result<ContentfulArray<ContentType>> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("content_types", parameters: matching), completion)
    }

    /**
     Fetch a collection of Content Types from Contentful

     - parameter matching: Optional list of search parameters the Content Types must match

     - returns: A tuple of data task and a signal for the resulting array of Content Types
     */
    public func fetchContentTypes(matching: [String:AnyObject] = [String:AnyObject]()) -> (NSURLSessionDataTask?, Signal<ContentfulArray<ContentType>>) {
        return signalify(matching, fetchContentTypes)
    }
}

extension ContentfulClient {
    /**
     Fetch a collection of Entries from Contentful

     - parameter matching:   Optional list of search parameters the Entries must match
     - parameter completion: A handler being called on completion of the request

     - returns: The data task being used, enables cancellation of requests
     */
    public func fetchEntries(matching: [String:AnyObject] = [String:AnyObject](), completion: Result<ContentfulArray<Entry>> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("entries", parameters: matching), completion)
    }

    /**
     Fetch a collection of Entries from Contentful

     - parameter matching: Optional list of search parameters the Entries must match

     - returns: A tuple of data task and a signal for the resulting array of Entries
     */
    public func fetchEntries(matching: [String:AnyObject] = [String:AnyObject]()) -> (NSURLSessionDataTask?, Signal<ContentfulArray<Entry>>) {
        return signalify(matching, fetchEntries)
    }

    /**
     Fetch a single Entry from Contentful

     - parameter identifier: The identifier of the Entry to be fetched
     - parameter completion: A handler being called on completion of the request

     - returns: The data task being used, enables cancellation of requests
     */
    public func fetchEntry(identifier: String, completion: Result<Entry> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment("entries/\(identifier)"), completion)
    }

    /**
     Fetch a single Entry from Contentful

     - parameter identifier: The identifier of the Entry to be fetched

     - returns: A tuple of data task and a signal for the resulting Entry
     */
    public func fetchEntry(identifier: String) -> (NSURLSessionDataTask?, Signal<Entry>) {
        return signalify(identifier, fetchEntry)
    }
}

extension ContentfulClient {
    /**
     Fetch the space this client is constrained to

     - parameter completion: A handler being called on completion of the request

     - returns: The data task being used, enables cancellation of requests
     */
    public func fetchSpace(completion: Result<Space> -> Void) -> NSURLSessionDataTask? {
        return fetch(URLForFragment(), completion)
    }

    /**
     Fetch the space this client is constrained to

     - returns: A tuple of data task and a signal for the resulting Space
     */
    public func fetchSpace() -> (NSURLSessionDataTask?, Signal<Space>) {
        return signalify(fetchSpace)
    }
}