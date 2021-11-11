# Marvel Heroes App: this app intends to fetch a list of heroes and a detail of each of them.


## Architecture Details: 
* Folder's distribution is: App(UI), Domain(UseCases), Data(Repositories and Network layer)
* UI design pattern used is MVVM+Router for a basic communication between ViewController (UIKit based), ViewModel and a Router.
* Usage of Combine framework to handle network requests and bindings to accomplish MVVM design pattern.
* App Transport Security Settings admits arbitrary loads to download properly images from Marvel. In case of centralizing its domain we could just add this specific case.
* There is a basic CoreData usage for cached image retrieval. Once fetching an image from a url path it is cached for future retrievals.

## UI Details:
* **Home** contains a UITableView which displays cells containing each character received from Network. There is no Cache System for failure case at the moment, later on a CoreData cache based will be implemented.
* Once getting to the last item displayed on the table, more items are fetched and later on displayed.
* Cells displayed on home contain an image, a title and a description. Once clicking into one of them a detail is shown.

* **Detail** contains an image, a title, a description and a list of possible comic titles for the character selected.


## Testing:
There is the existence of the unit tests and integration tests, the latter in favor of slower UI tests.

* Unit tests coverage is on view controllers, view models, use cases, repositories and network layer.
* Integration tests flow covers view controller interaction through view model, and a mock response from use cases.


## Stack:
* Xcode 13
* iOS 15 

### API: [Marvel](https://developer.marvel.com/docs)
