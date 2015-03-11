//Copyright 2015 Esri
//Licensed under the Apache License, Version 2.0 (the "License");
//you may not use this file except in compliance with the License.
//You may obtain a copy of the License at
//http://www.apache.org/licenses/LICENSE-2.0
//Unless required by applicable law or agreed to in writing, software
//distributed under the License is distributed on an "AS IS" BASIS,
//WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//See the License for the specific language governing permissions and
//limitations under the License.

#import <UIKit/UIKit.h>
#import <ArcGIS/ArcGIS.h>

@interface GeocodingSampleViewController : UIViewController <UISearchBarDelegate, AGSLocatorDelegate, AGSCalloutDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate> {
    NSOperation                 *_findOperation;
    NSOperation                 *_suggestOperation;
}

@property (nonatomic, strong) IBOutlet AGSMapView *mapView;
@property (nonatomic, strong) IBOutlet UISearchBar *searchBar;

@property (nonatomic, strong) IBOutlet UITableView *suggestionsTableView;
@property (nonatomic, strong) AGSGraphicsLayer *graphicsLayer;
@property (nonatomic, strong) AGSLocator *locator;
@property (nonatomic, strong) AGSCalloutTemplate *calloutTemplate;



//This is the method that starts the geocoding operation
- (void)startGeocoding;

@end

