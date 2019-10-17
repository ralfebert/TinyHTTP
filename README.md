# TinyHTTP

TinyHTTP is yet another minimalistic abstraction for making network calls with URLSession designed for making JSON/REST calls in iOS apps in a controller-owned-networking style design.

Inspired by [TinyNetworking](https://github.com/objcio/tiny-networking) and [Siesta](https://bustoutsolutions.github.io/siesta/).

Includes:

* A type `Endpoint` for describing a request and how the response is validated and decoded.
* A `StatefulEndpoint` for sharing and observing one endpoint from multiple places in a thread-safe way.
* Abstractions for making network calls in UIKit apps / in UIViewController classes with proper error handling and activity indication with sensible defaults for an easy 'works-out-of-the-box' experience while allowing full customization.
