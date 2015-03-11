// Copyright 2012 ESRI
//
// All rights reserved under the copyright laws of the United States
// and applicable international laws, treaties, and conventions.
//
// You may freely redistribute and use this sample code, with or
// without modification, provided you include the original copyright
// notice and use restrictions.
//
// See the use restrictions at http://help.arcgis.com/en/sdk/10.0/usageRestrictions.htm
//

#import "GeocodingSampleViewController.h"
#import "ResultsViewController.h"

#define kResultsViewController @"ResultsViewController"

//suggestions-related variables
UITableView *suggestionsTable;
NSMutableArray *suggestionsArray;
NSMutableArray *suggestionsJsonArray;
NSMutableArray *magicKeyJsonArray;
NSString *currentSearchInput;
BOOL suggestionUsed = false;
NSString *suggestionSelected;
NSString *magicKeyForSuggestionSelected;

//categories-related variables
UITableView *categoriesTable;
BOOL categoriesUsed = false;
BOOL categoriesSearchOnly = false;
UIButton *categoriesButton;
NSArray *categoriesArray;
UIButton *allCategoriesCheckbox;
BOOL allCategoriesCheckboxSelected;
UIButton *searchAllCategoriesButton;
UIButton *restaurantsCheckbox;
BOOL restaurantsCheckboxSelected = false;
UIButton *searchAllRestaurantsButton;
UIButton *coffeeCheckbox;
BOOL coffeeCheckboxSelected = false;
UIButton *searchAllCoffeeButton;
UIButton *hotelsCheckbox;
BOOL hotelsCheckboxSelected = false;
UIButton *searchAllHotelsButton;
UIButton *gasCheckbox;
BOOL gasCheckboxSelected = false;
UIButton *searchAllGasButton;
UIButton *atmCheckbox;
BOOL atmCheckboxSelected = false;
UIButton *searchAllAtmButton;
NSMutableArray *currentlySelectedCategories;

@implementation GeocodingSampleViewController

//The map service
static NSString *kMapServiceURL = @"http://services.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer";

//The geocode service
static NSString *kGeoLocatorURL = @"http://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer";

NSMutableArray *suggestionsArray;

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //set the delegate on the mapView so we get notifications for user interaction with the callout
    self.mapView.callout.delegate = self;
    
	//create an instance of a tiled map service layer
	//Add it to the map view
    NSURL *serviceUrl = [NSURL URLWithString:kMapServiceURL];
    AGSTiledMapServiceLayer *tiledMapServiceLayer = [AGSTiledMapServiceLayer tiledMapServiceLayerWithURL:serviceUrl];
    [self.mapView addMapLayer:tiledMapServiceLayer withName:@"World Street Map"];

    AGSEnvelope *palmSpringsEnvelope = [AGSEnvelope envelopeWithXmin:-12980000 ymin:4000000 xmax:-12950000 ymax:4010000 spatialReference:self.mapView.spatialReference];
    [self.mapView zoomToEnvelope:palmSpringsEnvelope animated:true];
    
    //create the graphics layer that the geocoding result
    //will be stored in and add it to the map
    self.graphicsLayer = [AGSGraphicsLayer graphicsLayer];
    [self.mapView addMapLayer:self.graphicsLayer withName:@"Graphics Layer"];
    
    //set the text and detail text based on 'Name' and 'Descr' fields in the results
    //create the callout template, used when the user displays the callout
    self.calloutTemplate = [[AGSCalloutTemplate alloc]init];
    self.calloutTemplate.titleTemplate = @"${Match_addr}";
    self.calloutTemplate.detailTemplate = @"${Place_addr}";
    self.graphicsLayer.calloutDelegate = self.calloutTemplate;
    
    UIButton *zoomOutButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [zoomOutButton setBackgroundImage:[UIImage imageNamed:@"zoom_out.png"] forState:UIControlStateNormal];
    zoomOutButton.frame = CGRectMake(290, 30, 30, 30);
    [zoomOutButton addTarget:self action:@selector(zoomOut) forControlEvents:UIControlEventTouchUpInside];
    zoomOutButton.backgroundColor= [UIColor clearColor];
    [self.mapView addSubview:zoomOutButton];
    UIButton *zoomInButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [zoomInButton setBackgroundImage:[UIImage imageNamed:@"zoom_in.png"] forState:UIControlStateNormal];
    zoomInButton.frame = CGRectMake(290, 0, 30, 30);
    [zoomInButton addTarget:self action:@selector(zoomIn) forControlEvents:UIControlEventTouchUpInside];
    zoomInButton.backgroundColor= [UIColor clearColor];
    [self.mapView addSubview:zoomInButton];
    
    //initialize the suggestions dropdown table and add as subview
    suggestionsTable = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 120) style:UITableViewStylePlain];
    suggestionsTable.rowHeight = 20;
    suggestionsTable.delegate = self;
    suggestionsTable.dataSource = self;
    suggestionsTable.scrollEnabled = NO;
    suggestionsTable.hidden = YES;
    [self.mapView addSubview:suggestionsTable];
    //Set up initial suggestions array
    suggestionsArray = [[NSMutableArray alloc] init];
    [suggestionsArray addObject:@""];
    [suggestionsArray addObject:@""];
    [suggestionsArray addObject:@""];
    [suggestionsArray addObject:@""];
    [suggestionsArray addObject:@""];
    [suggestionsArray addObject:@""];
    
    //initialize the categories popup table and add as subview
    categoriesButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [categoriesButton addTarget:self action:@selector(openCategoryView) forControlEvents:UIControlEventTouchUpInside];
    [categoriesButton setTitle:@"Select Categories" forState:UIControlStateNormal];
    categoriesButton.backgroundColor = [UIColor darkGrayColor];
    [categoriesButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    categoriesButton.frame = CGRectMake(155,450, 160.0, 40.0);
    [self.mapView addSubview:categoriesButton];
    categoriesTable = [[UITableView alloc] initWithFrame:CGRectMake(155, 330, 160, 120) style:UITableViewStylePlain];
    categoriesTable.rowHeight = 20;
    categoriesTable.backgroundColor = [UIColor darkGrayColor];
    categoriesTable.delegate = self;
    categoriesTable.dataSource = self;
    categoriesTable.scrollEnabled = NO;
    categoriesTable.hidden = YES;
    [self.mapView addSubview:categoriesTable];
    categoriesArray = [[NSArray alloc] initWithObjects:@"All Categories",@"Restaurants",@"Coffee",@"Hotels",@"Gas",@"ATMs", nil];
    currentlySelectedCategories = [[NSMutableArray alloc] init];
}

-(void)zoomOut {
    [self.mapView zoomOut:YES];
}

-(void)zoomIn {
    [self.mapView zoomIn:YES];
}

- (void)startGeocoding
{
    
    //clear out previous results
    [self.graphicsLayer removeAllGraphics];
    
    //create the AGSLocator with the geo locator URL
    //and set the delegate to self, so we get AGSLocatorDelegate notifications
    self.locator = [AGSLocator locatorWithURL:[NSURL URLWithString:kGeoLocatorURL]];
    self.locator.delegate = self;
    
    //Note that the "*" for out fields is supported for geocode services of
    //ArcGIS Server 10 and above
    //NSArray *outFields = [NSArray arrayWithObject:@"*"];
    AGSLocatorFindParameters *parameters = [[AGSLocatorFindParameters alloc] init];
    
    //performs search using the sdk method without any category or suggestions parameters
    if(!suggestionUsed && !categoriesUsed && !categoriesSearchOnly) {
        parameters.text =self.searchBar.text;
        parameters.outSpatialReference = self.mapView.spatialReference;
        parameters.outFields = @[@"*"];
        AGSPoint *location = [[AGSPoint alloc]initWithX:-116.538366 y:33.825678 spatialReference:nil];
        parameters.location = location; //add location for palm springs to refine results
        parameters.distance = 30000; //add distance for radius from palm springs to refine results
        parameters.maxLocations = 20;
        [self.locator findWithParameters:parameters];
    }
    
    //performs search using json request to AGOL World service with suggestion parameters
    else if(suggestionUsed && !categoriesUsed && !categoriesSearchOnly){
        suggestionUsed = NO;
        [[AGSRequestOperation sharedOperationQueue] cancelAllOperations];
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"json", @"f",
                                       nil];
        //json request includes location=palm springs convention center and distance=30000m
        //json request includes the string value of the suggestion selected by user
        //json request includes magic key value that corresponds to the selected suggestion
       NSString *searchString = [NSString stringWithFormat:@"http://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/findAddressCandidates?SingleLine=%@&outFields=*&maxLocations=20&location=-116.538366,33.825678&distance=30000&magicKey=%@&f=json", suggestionSelected, magicKeyForSuggestionSelected];
        NSString *encodedSearchString = [searchString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURL *searchUrl = [[NSURL alloc] initWithString:encodedSearchString];
        AGSJSONRequestOperation *requestOp = [[AGSJSONRequestOperation alloc]initWithURL:searchUrl queryParameters:params];
        requestOp.target = self;
        requestOp.action = @selector(requestOp:completedWithResultsGeocoder:);
        requestOp.errorAction = @selector(requestOp:failedNoResultsGeocoder:);
        
        [[AGSRequestOperation sharedOperationQueue] addOperation:requestOp];
    }
    
    //performs search using json request to AGOL World service with category and suggestion parameters
    else if(suggestionUsed && categoriesUsed &&!categoriesSearchOnly) {
        suggestionUsed = NO;
        [[AGSRequestOperation sharedOperationQueue] cancelAllOperations];
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"json", @"f",
                                       nil];
        
        //category strings for url must be built based on all currently selected categories
        NSMutableArray *currentlySelectedCategories = [[NSMutableArray alloc] init];
        if(restaurantsCheckboxSelected) [currentlySelectedCategories addObject:@"food"];
        if(coffeeCheckboxSelected) [currentlySelectedCategories addObject:@"coffee shop"];
        if(hotelsCheckboxSelected) [currentlySelectedCategories addObject:@"hotel"];
        if(gasCheckboxSelected) [currentlySelectedCategories addObject:@"gas station"];
        if(atmCheckboxSelected) [currentlySelectedCategories addObject:@"atm"];
        NSString *categoriesString = @"";
        for(int i=0; i<[currentlySelectedCategories count]; i++) {
            NSString *currentString =[currentlySelectedCategories objectAtIndex:i];
            if(i==0) {
                categoriesString = [categoriesString stringByAppendingString:currentString];
            }
            else {
                categoriesString = [categoriesString stringByAppendingString:@","];
                categoriesString = [categoriesString stringByAppendingString:currentString];
            }
        }
        
        //json request includes location=palm springs convention center and distance=30000m
        //json request includes the string value of the suggestion selected by user
        //json request includes magic key value that corresponds to the selected suggestion
        //json request includes category string generated above
        NSString *searchString = [NSString stringWithFormat:@"http://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/findAddressCandidates?SingleLine=%@&category=%@&outFields=*&maxLocations=20&location=-116.538366,33.825678&distance=100&magicKey=%@&f=json", suggestionSelected, categoriesString, magicKeyForSuggestionSelected];
        NSString *encodedSearchString = [searchString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURL *searchUrl = [[NSURL alloc] initWithString:encodedSearchString];
        AGSJSONRequestOperation *requestOp = [[AGSJSONRequestOperation alloc]initWithURL:searchUrl queryParameters:params];
        requestOp.target = self;
        requestOp.action = @selector(requestOp:completedWithResultsGeocoder:);
        requestOp.errorAction = @selector(requestOp:failedNoResultsGeocoder:);
        
        [[AGSRequestOperation sharedOperationQueue] addOperation:requestOp];
    }
    
    //performs search using json request to AGOL World service with category parameters
    else if(!suggestionUsed && categoriesUsed && !categoriesSearchOnly) {
        [[AGSRequestOperation sharedOperationQueue] cancelAllOperations];
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"json", @"f",
                                       nil];
        
        //category strings for url must be built based on all currently selected categories
        NSMutableArray *currentlySelectedCategories = [[NSMutableArray alloc] init];
        if(restaurantsCheckboxSelected) [currentlySelectedCategories addObject:@"food"];
        if(coffeeCheckboxSelected) [currentlySelectedCategories addObject:@"coffee shop"];
        if(hotelsCheckboxSelected) [currentlySelectedCategories addObject:@"hotel"];
        if(gasCheckboxSelected) [currentlySelectedCategories addObject:@"gas station"];
        if(atmCheckboxSelected) [currentlySelectedCategories addObject:@"atm"];
        NSString *categoriesString = @"";
        for(int i=0; i<[currentlySelectedCategories count]; i++) {
            NSString *currentString =[currentlySelectedCategories objectAtIndex:i];
            if(i==0) {
                categoriesString = [categoriesString stringByAppendingString:currentString];
            }
            else {
                categoriesString = [categoriesString stringByAppendingString:@","];
                categoriesString = [categoriesString stringByAppendingString:currentString];
            }
        }
        NSString *searchText = self.searchBar.text;
        
        //json request includes value for searchExtent = palm springs region (there is a known issue using location/distance with category search when suggestion/magicKey not included)
        //json request includes the string value of the text input into the search box by the user
        //json request includes category string generated above
        NSString *searchString = [NSString stringWithFormat:@"http://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/findAddressCandidates?SingleLine=%@&category=%@&outFields=*&maxLocations=20&searchExtent=-116.650997,34.010731,-116.154553,33.639385&f=json", searchText, categoriesString];
        NSString *encodedSearchString = [searchString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURL *searchUrl = [[NSURL alloc] initWithString:encodedSearchString];
        AGSJSONRequestOperation *requestOp = [[AGSJSONRequestOperation alloc]initWithURL:searchUrl queryParameters:params];
        requestOp.target = self;
        requestOp.action = @selector(requestOp:completedWithResultsGeocoder:);
        requestOp.errorAction = @selector(requestOp:failedNoResultsGeocoder:);
        
        [[AGSRequestOperation sharedOperationQueue] addOperation:requestOp];
    }
    
    //performs search using json request to AGOL World service with category parameters and blank input text
    //this returns all top results for category only regardless of name
    else if(categoriesSearchOnly) {
        categoriesSearchOnly = NO;
        [[AGSRequestOperation sharedOperationQueue] cancelAllOperations];
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                       @"json", @"f",
                                       nil];
        //category strings for url must be built based on all currently selected categories
        if(currentlySelectedCategories == nil || [currentlySelectedCategories count]==0) {
            if(restaurantsCheckboxSelected) [currentlySelectedCategories addObject:@"food"];
            if(coffeeCheckboxSelected) [currentlySelectedCategories addObject:@"coffee shop"];
            if(hotelsCheckboxSelected) [currentlySelectedCategories addObject:@"hotel"];
            if(gasCheckboxSelected) [currentlySelectedCategories addObject:@"gas station"];
            if(atmCheckboxSelected) [currentlySelectedCategories addObject:@"atm"];
        }
        NSString *categoriesString = @"";
        for(int i=0; i<[currentlySelectedCategories count]; i++) {
            NSString *currentString =[currentlySelectedCategories objectAtIndex:i];
            if(i==0) {
                categoriesString = [categoriesString stringByAppendingString:currentString];
            }
            else {
                categoriesString = [categoriesString stringByAppendingString:@","];
                categoriesString = [categoriesString stringByAppendingString:currentString];
            }
        }
        currentlySelectedCategories = nil;
        currentlySelectedCategories = [[NSMutableArray alloc] init];
        
        //json request includes value for searchExtent = palm springs region (there is a known issue using location/distance with category search when suggestion/magicKey not included)
        //json request includes the empty searchText so that all results will be returned for selected categories
        NSString *searchString = [NSString stringWithFormat:@"http://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/findAddressCandidates?&category=%@&outFields=*&maxLocations=20&searchExtent=-116.650997,34.010731,-116.154553,33.639385&f=json", categoriesString];
        NSString *encodedSearchString = [searchString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURL *searchUrl = [[NSURL alloc] initWithString:encodedSearchString];
        AGSJSONRequestOperation *requestOp = [[AGSJSONRequestOperation alloc]initWithURL:searchUrl queryParameters:params];
        requestOp.target = self;
        requestOp.action = @selector(requestOp:completedWithResultsGeocoder:);
        requestOp.errorAction = @selector(requestOp:failedNoResultsGeocoder:);
        
        [[AGSRequestOperation sharedOperationQueue] addOperation:requestOp];
    }
}

//still need to implement category support for suggestions
- (void) getSuggestions {
    //create the AGSLocator with the geo locator URL
    //and set the delegate to self, so we get AGSLocatorDelegate notifications
    self.locator = [AGSLocator locatorWithURL:[NSURL URLWithString:kGeoLocatorURL]];
    self.locator.delegate = self;
    
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                   @"json", @"f",
                                   nil];
    NSString *categoriesString = @"&category=";
    if(restaurantsCheckboxSelected) [currentlySelectedCategories addObject:@"food"];
    if(coffeeCheckboxSelected) [currentlySelectedCategories addObject:@"coffee shop"];
    if(hotelsCheckboxSelected) [currentlySelectedCategories addObject:@"hotel"];
    if(gasCheckboxSelected) [currentlySelectedCategories addObject:@"gas station"];
    if(atmCheckboxSelected) [currentlySelectedCategories addObject:@"atm"];
    for(int i=0; i<[currentlySelectedCategories count]; i++) {
        NSString *currentString =[currentlySelectedCategories objectAtIndex:i];
        if(i==0) {
            categoriesString = [categoriesString stringByAppendingString:currentString];
        }
        else {
            categoriesString = [categoriesString stringByAppendingString:@","];
            categoriesString = [categoriesString stringByAppendingString:currentString];
        }
    }
    currentlySelectedCategories = nil;
    currentlySelectedCategories = [[NSMutableArray alloc] init];
    NSString *suggestString =[NSString stringWithFormat:@"http://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/suggest?text=%@%@&location=-116.538366,33.825678&distance=10000&f=json",currentSearchInput, categoriesString];
    NSString *encodedSearchString = [suggestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *suggestURL = [[NSURL alloc] initWithString:encodedSearchString];
    AGSJSONRequestOperation *requestOp = [[AGSJSONRequestOperation alloc]initWithURL:suggestURL resource:@"suggest" queryParameters:params];
    requestOp.target = self;
    requestOp.action = @selector(requestOp:completedWithResultsSuggestions:);
    requestOp.errorAction = @selector(requestOp:failedNoResultsSuggest:);
    [[AGSRequestOperation sharedOperationQueue] addOperation:requestOp];
}

- (void) openCategoryView {
    if(categoriesTable.hidden) categoriesTable.hidden = NO;
    else categoriesTable.hidden = YES;
}

#pragma mark -
#pragma mark AGSCalloutDelegate

- (void) didClickAccessoryButtonForCallout:(AGSCallout *) 	callout
{
    AGSGraphic* graphic = (AGSGraphic*) callout.representedObject;
    
    //The user clicked the callout button, so display the complete set of results
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Storyboard" bundle:[NSBundle mainBundle]];
    ResultsViewController *resultsVC = [storyboard instantiateViewControllerWithIdentifier:kResultsViewController];

    //set our attributes/results into the results VC
    resultsVC.results = [graphic allAttributes];
    
    //display the results vc modally
    [self presentViewController:resultsVC animated:YES completion:nil];
}

#pragma mark -
#pragma mark AGSLocatorDelegate

-(void) requestOp:(NSOperation*)op completedWithResultsSuggestions:(NSDictionary*)results {
    //NSLog(@"%@", results);
    //generate suggestions to display in suggestions table
    NSArray *jsonArray = [results valueForKey:@"suggestions"];
    suggestionsJsonArray = [jsonArray valueForKey:@"text"];
    magicKeyJsonArray = [jsonArray valueForKey:@"magicKey"];
    for(int i=0; i<[suggestionsArray count]; i++) {
        if(i <[suggestionsJsonArray count]) {
            [suggestionsArray replaceObjectAtIndex:i withObject:[suggestionsJsonArray objectAtIndex:i]];
        }
        else [suggestionsArray replaceObjectAtIndex:i withObject:@""];
    }
    
    //Refresh the tableView so that updated suggestions are shown
    [suggestionsTable reloadData];
    [self refreshSuggestionsTableSize];
}

//handle the results returned by the json request to findAddressCandidates
- (void)requestOp:(AGSJSONRequestOperation*)op completedWithResultsGeocoder:(NSDictionary*)results {
    //NSLog(@"%@", results);
    //json for all candidates returned
    NSArray *allCandidatesJson = [results valueForKey:@"candidates"];

    //check and see if we didn't get any results
    if (results == nil || [results count] == 0)
    {
        //show alert if we didn't get results
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Results"
                                                        message:@"No Results Found By Locator"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        
        [alert show];
    }
    else
    {
        //loop through all candidates/results and add to graphics layer
        for (int i=0; i<[allCandidatesJson count]; i++)
        {
            //set spatial reference //this could be set from JSON -- do this!
            AGSSpatialReference *candidateSpatialReference = [[AGSSpatialReference alloc] initWithWKID:4326];
            
            //get the location from the candidate json
            NSArray *currentCandidateJson = [allCandidatesJson objectAtIndex:i];
            NSArray *currentCandidateLocationJson = [currentCandidateJson valueForKey:@"location"];
            double currentCandidateLocationX = [[currentCandidateLocationJson valueForKey:@"x"]floatValue];
            double currentCandidateLocationY = [[currentCandidateLocationJson valueForKey:@"y"]floatValue];
            
            //create point with correct geometry for current candidate
            AGSPoint *pt = [[AGSPoint alloc] initWithX:currentCandidateLocationX y:currentCandidateLocationY spatialReference:candidateSpatialReference];
            AGSGeometry *pg = [[AGSGeometryEngine defaultGeometryEngine] projectGeometry:pt toSpatialReference:self.mapView.spatialReference];
            
            //create a marker symbol to use in our graphic
            AGSPictureMarkerSymbol *marker = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImageNamed:@"BluePushpin.png"];
            marker.offset = CGPointMake(9,16);
            marker.leaderPoint = CGPointMake(-9, 11);
            
            //get extent attributes
            NSArray *extentJson = [currentCandidateJson valueForKey:@"extent"];
            NSString *xmax = [NSString stringWithFormat:@"%@", [extentJson valueForKey:@"xmax"]];
            NSString *xmin = [NSString stringWithFormat:@"%@", [extentJson valueForKey:@"xmin"]];
            NSString *ymax = [NSString stringWithFormat:@"%@", [extentJson valueForKey:@"ymax"]];
            NSString *ymin = [NSString stringWithFormat:@"%@", [extentJson valueForKey:@"ymin"]];
            
            //get Score attribute
            NSArray *attrJson = [currentCandidateJson valueForKey:@"attributes"];
            NSString *score = [attrJson valueForKey:@"Score"];
            NSString *addrType = [attrJson valueForKey:@"Addr_type"];
            NSString *locName = [attrJson valueForKey:@"Loc_name"];
            NSString *matchAddr = [attrJson valueForKey:@"Match_addr"];
            NSString *placeAddr = [attrJson valueForKey:@"Place_addr"];
            
            //generate all candidate attribute to add to graphic
            NSDictionary *candidateAttributes=[[NSDictionary alloc] initWithObjectsAndKeys:matchAddr,@"Match_addr",placeAddr,@"Place_addr",xmax,@"Xmax",xmin,@"Xmin",ymax,@"Ymax",ymin,@"Ymin",score,@"Score",addrType, @"Addr_type",locName,@"Loc_name",nil];
            
            //generate graphic to add to mapView
            AGSGraphic *graphic = [[AGSGraphic alloc] initWithGeometry:pg symbol:marker attributes:candidateAttributes];
            [graphic setSymbol:marker];
            
            
            //add the graphic to the graphics layer
            [self.graphicsLayer addGraphic:graphic];
            
            //if we have one result
            if ([allCandidatesJson count] == 1)
            {
                [self.mapView centerAtPoint:pt animated:NO]; //center at single point
                self.mapView.callout.width = 250; //set callout width
                //show the callout
                [self.mapView.callout showCalloutAtPoint:pt forFeature:graphic layer:graphic.layer animated:YES];
            }
        }
        //if we have more than one result, zoom to the extent of all results
        NSUInteger nCount = [results count];
        if (nCount > 1)
        {
            [self.mapView zoomToEnvelope:self.graphicsLayer.fullEnvelope animated:YES];
        }
    }
    //reset current suggestion and magic key values for next search
    suggestionSelected = nil;
    magicKeyForSuggestionSelected = nil;
}

- (void)requestOp:(AGSJSONRequestOperation*)op failedNoResultsGeocoder:(NSError*)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Results"
                                                    message:@"No Results Found By Locator"
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    
    [alert show];
    //NSLog(@"%@", error.description);
}

- (void)requestOp:(AGSJSONRequestOperation*)op failedNoResultsSuggest:(NSError*)error {
    //generate blank suggestions to display in suggestions table
    for(int i=0; i<[suggestionsArray count]; i++) {
        [suggestionsArray replaceObjectAtIndex:i withObject:@""];
    }
    //Refresh the tableView so that updated suggestions are shown
    [suggestionsTable reloadData];
    [self refreshSuggestionsTableSize];
}

//handle results returned from sdk call to geocoder (non-json operation)
- (void)locator:(AGSLocator*)locator operation:(NSOperation*)op didFind:(NSArray*)results
{
    //check and see if we didn't get any results
	if (results == nil || [results count] == 0)
	{
        //show alert if we didn't get results
         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Results"
                                                         message:@"No Results Found By Locator"
                                                        delegate:nil
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
        
        [alert show];
	}
	else
	{
        //loop through all candidates/results and add to graphics layer
        for (int i=0; i<[results count]; i++)
		{
            AGSLocatorFindResult *addressCandidate = (AGSLocatorFindResult *)results[i];

            //get the location from the candidate
            AGSPoint *pt = (AGSPoint*)addressCandidate.graphic.geometry;
            
			//create a marker symbol to use in our graphic
            AGSPictureMarkerSymbol *marker = [AGSPictureMarkerSymbol pictureMarkerSymbolWithImageNamed:@"BluePushpin.png"];
            marker.offset = CGPointMake(9,16);
            marker.leaderPoint = CGPointMake(-9, 11);
            [addressCandidate.graphic setSymbol:marker];
            
            //add the graphic to the graphics layer
			[self.graphicsLayer addGraphic:addressCandidate.graphic];
			            
                if ([results count] == 1)
                {
                    //we have one result, center at that point
                    [self.mapView centerAtPoint:pt animated:NO];
                    
                    // set the width of the callout
                    self.mapView.callout.width = 250;
                    
                    //show the callout
                    [self.mapView.callout showCalloutAtPoint:(AGSPoint*)addressCandidate.graphic.geometry forFeature:addressCandidate.graphic layer:addressCandidate.graphic.layer animated:YES];
                }
		}
        //if we have more than one result, zoom to the extent of all results
        NSUInteger nCount = [results count];
        if (nCount > 1)
        {
			[self.mapView zoomToEnvelope:self.graphicsLayer.fullEnvelope animated:YES];
        }
	}
}


//this handles failure for operation performed through sdk (non-json operation)
- (void)locator:(AGSLocator *)locator operation:(NSOperation *)op didFailLocationsForAddress:(NSError *)error
{
    //The location operation failed, display the error
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Locator Failed"
                                                    message:[NSString stringWithFormat:@"Error: %@", error.description]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"                                          
                                          otherButtonTitles:nil];

    [alert show];
}

#pragma mark _
#pragma mark UISearchBarDelegate

- (void) searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    //categories popup should hide when user clicks over to search
    suggestionsTable.hidden = NO;
    categoriesTable.hidden = YES;
    //candidate popups should hide when user clicks over to search
    [self.mapView.callout dismiss];
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    //show suggestions dropdown when user starts typing
    suggestionsTable.hidden = NO;
    //generate suggestions based on input
    currentSearchInput = searchText;
    [self getSuggestions];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
	//hide the callout
	self.mapView.callout.hidden = YES;
    //hide the suggestions dropdown
    suggestionsTable.hidden = YES;
    //check if categories being used
	if(restaurantsCheckboxSelected==true || hotelsCheckboxSelected==true ||coffeeCheckboxSelected==true || gasCheckboxSelected || atmCheckboxSelected==true) categoriesUsed = true;
    //First, hide the keyboard, then starGeocoding
    [searchBar resignFirstResponder];
    [self startGeocoding];
}



- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(tableView==suggestionsTable) {
        //suggestions dropdown should hide after user clicks a suggestion
        self.mapView.callout.hidden = YES;
        suggestionsTable.hidden = YES;
        //Get the cell at indexPath in order to check text
        UITableViewCell *cell = [suggestionsTable cellForRowAtIndexPath:indexPath];
        NSString *cellText = cell.textLabel.text;
        //if text is option to search based on category only - perform categories-only search, ignore suggestions
        if([cellText isEqual:@"Search for selected categories using location."]) {
            categoriesSearchOnly = true;
            [self.searchBar resignFirstResponder];
            [self startGeocoding];
        }
        else {
            //use index of suggestion to get index to use for suggestions array (off by one if categories selected)
            NSInteger index;
            if(restaurantsCheckboxSelected==true || coffeeCheckboxSelected==true || hotelsCheckboxSelected==true || gasCheckboxSelected==true || atmCheckboxSelected==true) {
                index = indexPath.row - 1;
            }
            else index = indexPath.row;
            //set suggestions and magic key values
            suggestionSelected = [suggestionsJsonArray objectAtIndex:index];
            magicKeyForSuggestionSelected = [magicKeyJsonArray objectAtIndex:index];
            if(restaurantsCheckboxSelected==true || hotelsCheckboxSelected==true ||coffeeCheckboxSelected==true || gasCheckboxSelected || atmCheckboxSelected==true) categoriesUsed = true;
            suggestionUsed = true;
            //hide search bar and begin geocoding
            [self.searchBar resignFirstResponder];
            [self startGeocoding];
        }
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    //hide the suggestions dropdown when search is cancelled
    [searchBar resignFirstResponder];
    suggestionsTable.hidden = YES;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //if results is not nil and we have results, return that number
    if(tableView==suggestionsTable) {
        return ((suggestionsArray != nil && [suggestionsArray count] > 0) ? [suggestionsArray count] : 0);
    }
    else {
        return ((categoriesArray != nil && [categoriesArray count] > 0) ? [categoriesArray count] : 0);
    }
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    //set appearance of suggestions dropdown table
    if(tableView==suggestionsTable) {
        UITableViewCell *cell = nil;
        static NSString *SuggestionsRowIdentifier = @"SuggestionsRowIdentifier";
        cell = [tableView dequeueReusableCellWithIdentifier:SuggestionsRowIdentifier];
        cell.userInteractionEnabled = YES;
        if (cell == nil) {
            cell = [[UITableViewCell alloc]
                initWithStyle:UITableViewCellStyleDefault reuseIdentifier:SuggestionsRowIdentifier];
            cell.backgroundColor = [UIColor darkGrayColor];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        //get total number of suggestions so that table size can adjust dynamically
        int totalSuggestions=0;
        for(int i=0; i<[suggestionsArray count]; i++) {
            if([[suggestionsArray objectAtIndex:indexPath.row] length] > 1) totalSuggestions++;
        }
        //if categories selected, include extra top row to search based on category only
        if(restaurantsCheckboxSelected==true || coffeeCheckboxSelected==true || hotelsCheckboxSelected==true || gasCheckboxSelected==true || atmCheckboxSelected==true) {
            if(indexPath.row==0) {
                cell.textLabel.text = @"Search for selected categories using location.";
            }
            else cell.textLabel.text = [suggestionsArray objectAtIndex:(indexPath.row-1)];
            cell.userInteractionEnabled = YES;
        }
        //if categories not selected, display standard 5 (or fewer) rows for suggestions
        else {
            cell.textLabel.text = [suggestionsArray objectAtIndex:indexPath.row];
            if(totalSuggestions==0) {
                CGRect newFrameSize = {0, 0, 320, 20};
                [tableView setFrame:newFrameSize];
                cell.textLabel.text = @"No suggestions found.";
                cell.userInteractionEnabled = NO;
            }
        }
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.font = [UIFont systemFontOfSize:12.0];
        return cell;
    }
    //set appearance of categories popup table
    else {
        UITableViewCell *cell = nil;
        static NSString *categoriesRowIdentifier = @"CategoriesRowIdentifier";
        cell = [tableView dequeueReusableCellWithIdentifier:categoriesRowIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]
                    initWithStyle:UITableViewCellStyleDefault reuseIdentifier:categoriesRowIdentifier];
            cell.backgroundColor = [UIColor grayColor];
        }
        cell.textLabel.text = [categoriesArray objectAtIndex:indexPath.row];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if(indexPath.row==0) {
            allCategoriesCheckbox = [UIButton buttonWithType:UIButtonTypeCustom];
            //set the position of the button
            [allCategoriesCheckbox setBackgroundImage:[UIImage imageNamed:@"checkbox_empty.png"] forState:UIControlStateNormal];
            [allCategoriesCheckbox setBackgroundImage:[UIImage imageNamed:@"checkbox_full.png"] forState:UIControlStateSelected];
            allCategoriesCheckbox.frame = CGRectMake(cell.frame.origin.x + 123, cell.frame.origin.y, 19, 19);
            [allCategoriesCheckbox addTarget:self action:@selector(allCategoriesCheckboxClicked) forControlEvents:UIControlEventTouchUpInside];
            allCategoriesCheckbox.backgroundColor= [UIColor clearColor];
            [cell.contentView addSubview:allCategoriesCheckbox];
            searchAllCategoriesButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [searchAllCategoriesButton setBackgroundImage:[UIImage imageNamed:@"search.png"] forState:UIControlStateNormal];
            searchAllCategoriesButton.frame = CGRectMake(cell.frame.origin.x + 142, cell.frame.origin.y, 19, 19);
            [searchAllCategoriesButton addTarget:self action:@selector(searchAllCategories) forControlEvents:UIControlEventTouchUpInside];
            searchAllCategoriesButton.backgroundColor= [UIColor clearColor];
            [cell.contentView addSubview:searchAllCategoriesButton];
        }
        else if(indexPath.row==1) {
            restaurantsCheckbox = [UIButton buttonWithType:UIButtonTypeCustom];
            //set the position of the button
            [restaurantsCheckbox setBackgroundImage:[UIImage imageNamed:@"checkbox_empty.png"] forState:UIControlStateNormal];
            [restaurantsCheckbox setBackgroundImage:[UIImage imageNamed:@"checkbox_full.png"] forState:UIControlStateSelected];
            restaurantsCheckbox.frame = CGRectMake(cell.frame.origin.x + 123, cell.frame.origin.y, 19, 19);
            [restaurantsCheckbox addTarget:self action:@selector(restaurantsCheckboxClicked) forControlEvents:UIControlEventTouchUpInside];
            restaurantsCheckbox.backgroundColor= [UIColor clearColor];
            [cell.contentView addSubview:restaurantsCheckbox];
            searchAllRestaurantsButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [searchAllRestaurantsButton setBackgroundImage:[UIImage imageNamed:@"search.png"] forState:UIControlStateNormal];
            searchAllRestaurantsButton.frame = CGRectMake(cell.frame.origin.x + 142, cell.frame.origin.y, 19, 19);
            [searchAllRestaurantsButton addTarget:self action:@selector(searchAllRestaurants) forControlEvents:UIControlEventTouchUpInside];
            searchAllRestaurantsButton.backgroundColor= [UIColor clearColor];
            [cell.contentView addSubview:searchAllRestaurantsButton];
        }
        else if(indexPath.row==2) {
            coffeeCheckbox = [UIButton buttonWithType:UIButtonTypeCustom];
            //set the position of the button
            [coffeeCheckbox setBackgroundImage:[UIImage imageNamed:@"checkbox_empty.png"] forState:UIControlStateNormal];
            [coffeeCheckbox setBackgroundImage:[UIImage imageNamed:@"checkbox_full.png"] forState:UIControlStateSelected];
            coffeeCheckbox.frame = CGRectMake(cell.frame.origin.x + 123, cell.frame.origin.y, 19, 19);
            [coffeeCheckbox addTarget:self action:@selector(coffeeCheckboxClicked) forControlEvents:UIControlEventTouchUpInside];
            coffeeCheckbox.backgroundColor= [UIColor clearColor];
            [cell.contentView addSubview:coffeeCheckbox];
            searchAllCoffeeButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [searchAllCoffeeButton setBackgroundImage:[UIImage imageNamed:@"search.png"] forState:UIControlStateNormal];
            searchAllCoffeeButton.frame = CGRectMake(cell.frame.origin.x + 142, cell.frame.origin.y, 19, 19);
            [searchAllCoffeeButton addTarget:self action:@selector(searchAllCoffee) forControlEvents:UIControlEventTouchUpInside];
            searchAllCoffeeButton.backgroundColor= [UIColor clearColor];
            [cell.contentView addSubview:searchAllCoffeeButton];
        }
        else if(indexPath.row==3) {
            hotelsCheckbox = [UIButton buttonWithType:UIButtonTypeCustom];
            //set the position of the button
            [hotelsCheckbox setBackgroundImage:[UIImage imageNamed:@"checkbox_empty.png"] forState:UIControlStateNormal];
            [hotelsCheckbox setBackgroundImage:[UIImage imageNamed:@"checkbox_full.png"] forState:UIControlStateSelected];
            hotelsCheckbox.frame = CGRectMake(cell.frame.origin.x + 123, cell.frame.origin.y, 19, 19);
            [hotelsCheckbox addTarget:self action:@selector(hotelsCheckboxClicked) forControlEvents:UIControlEventTouchUpInside];
            hotelsCheckbox.backgroundColor= [UIColor clearColor];
            [cell.contentView addSubview:hotelsCheckbox];
            searchAllHotelsButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [searchAllHotelsButton setBackgroundImage:[UIImage imageNamed:@"search.png"] forState:UIControlStateNormal];
            searchAllHotelsButton.frame = CGRectMake(cell.frame.origin.x + 142, cell.frame.origin.y, 19, 19);
            [searchAllHotelsButton addTarget:self action:@selector(searchAllHotels) forControlEvents:UIControlEventTouchUpInside];
            searchAllHotelsButton.backgroundColor= [UIColor clearColor];
            [cell.contentView addSubview:searchAllHotelsButton];
        }
        else if(indexPath.row==4) {
            gasCheckbox = [UIButton buttonWithType:UIButtonTypeCustom];
            //set the position of the button
            [gasCheckbox setBackgroundImage:[UIImage imageNamed:@"checkbox_empty.png"] forState:UIControlStateNormal];
            [gasCheckbox setBackgroundImage:[UIImage imageNamed:@"checkbox_full.png"] forState:UIControlStateSelected];
            gasCheckbox.frame = CGRectMake(cell.frame.origin.x + 123, cell.frame.origin.y, 19, 19);
            [gasCheckbox addTarget:self action:@selector(gasCheckboxClicked) forControlEvents:UIControlEventTouchUpInside];
            gasCheckbox.backgroundColor= [UIColor clearColor];
            [cell.contentView addSubview:gasCheckbox];
            searchAllGasButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [searchAllGasButton setBackgroundImage:[UIImage imageNamed:@"search.png"] forState:UIControlStateNormal];
            searchAllGasButton.frame = CGRectMake(cell.frame.origin.x + 142, cell.frame.origin.y, 19, 19);
            [searchAllGasButton addTarget:self action:@selector(searchAllGas) forControlEvents:UIControlEventTouchUpInside];
            searchAllGasButton.backgroundColor= [UIColor clearColor];
            [cell.contentView addSubview:searchAllGasButton];
        }
        else if(indexPath.row==5) {
            atmCheckbox = [UIButton buttonWithType:UIButtonTypeCustom];
            //set the position of the button
            [atmCheckbox setBackgroundImage:[UIImage imageNamed:@"checkbox_empty.png"] forState:UIControlStateNormal];
            [atmCheckbox setBackgroundImage:[UIImage imageNamed:@"checkbox_full.png"] forState:UIControlStateSelected];
            atmCheckbox.frame = CGRectMake(cell.frame.origin.x + 123, cell.frame.origin.y, 19, 19);
            [atmCheckbox addTarget:self action:@selector(atmCheckboxClicked) forControlEvents:UIControlEventTouchUpInside];
            atmCheckbox.backgroundColor= [UIColor clearColor];
            [cell.contentView addSubview:atmCheckbox];
            searchAllAtmButton = [UIButton buttonWithType:UIButtonTypeCustom];
            [searchAllAtmButton setBackgroundImage:[UIImage imageNamed:@"search.png"] forState:UIControlStateNormal];
            searchAllAtmButton.frame = CGRectMake(cell.frame.origin.x + 142, cell.frame.origin.y, 19, 19);
            [searchAllAtmButton addTarget:self action:@selector(searchAllAtms) forControlEvents:UIControlEventTouchUpInside];
            searchAllAtmButton.backgroundColor= [UIColor clearColor];
            [cell.contentView addSubview:searchAllAtmButton];
        }
        
        return cell;
    }
}

-(void) refreshSuggestionsTableSize {
    //get total number of suggestions so that table size can adjust dynamically
    int totalSuggestions=0;
    for(int i=0; i<[suggestionsArray count]; i++) {
        if([[suggestionsArray objectAtIndex:i] length] > 1) totalSuggestions++;
    }
    if(restaurantsCheckboxSelected==true || coffeeCheckboxSelected==true || hotelsCheckboxSelected==true || gasCheckboxSelected==true || atmCheckboxSelected==true) totalSuggestions++;
    if(totalSuggestions>5) {
        CGRect newFrameSize = {0, 0, 320, 120};
        [suggestionsTable setFrame:newFrameSize];
    }
    else if(totalSuggestions==5) {
        CGRect newFrameSize = {0, 0, 320, 100};
        [suggestionsTable setFrame:newFrameSize];
    }
    else if(totalSuggestions==4) {
        CGRect newFrameSize = {0, 0, 320, 80};
        [suggestionsTable setFrame:newFrameSize];
    }
    else if(totalSuggestions==3) {
        CGRect newFrameSize = {0, 0, 320, 60};
        [suggestionsTable setFrame:newFrameSize];
    }
    else if(totalSuggestions==2) {
        CGRect newFrameSize = {0, 0, 320, 40};
        [suggestionsTable setFrame:newFrameSize];
    }
    else if(totalSuggestions==1) {
        CGRect newFrameSize = {0, 0, 320, 20};
        [suggestionsTable setFrame:newFrameSize];
    }
    else if(totalSuggestions==0) {
        CGRect newFrameSize = {0, 0, 320, 20};
        [suggestionsTable setFrame:newFrameSize];
    }
}

-(void) allCategoriesCheckboxClicked {
    allCategoriesCheckboxSelected = !allCategoriesCheckboxSelected;
    [allCategoriesCheckbox setSelected:allCategoriesCheckboxSelected];
    if(allCategoriesCheckboxSelected) {
        restaurantsCheckboxSelected = true;
        [restaurantsCheckbox setSelected:restaurantsCheckboxSelected];
        coffeeCheckboxSelected = true;
        [coffeeCheckbox setSelected:coffeeCheckboxSelected];
        hotelsCheckboxSelected = true;
        [hotelsCheckbox setSelected:hotelsCheckboxSelected];
        gasCheckboxSelected = true;
        [gasCheckbox setSelected:gasCheckboxSelected];
        atmCheckboxSelected = true;
        [atmCheckbox setSelected:atmCheckboxSelected];
    }
    else {
        restaurantsCheckboxSelected = false;
        [restaurantsCheckbox setSelected:restaurantsCheckboxSelected];
        coffeeCheckboxSelected = false;
        [coffeeCheckbox setSelected:coffeeCheckboxSelected];
        hotelsCheckboxSelected = false;
        [hotelsCheckbox setSelected:hotelsCheckboxSelected];
        gasCheckboxSelected = false;
        [gasCheckbox setSelected:gasCheckboxSelected];
        atmCheckboxSelected = false;
        [atmCheckbox setSelected:atmCheckboxSelected];
    }
    [suggestionsTable reloadData];
}

-(void) restaurantsCheckboxClicked {
    restaurantsCheckboxSelected = !restaurantsCheckboxSelected;
    [restaurantsCheckbox setSelected:restaurantsCheckboxSelected];
    if(allCategoriesCheckboxSelected) {
        allCategoriesCheckboxSelected = !allCategoriesCheckboxSelected;
        [allCategoriesCheckbox setSelected:allCategoriesCheckboxSelected];
    }
    [suggestionsTable reloadData];
}

-(void) coffeeCheckboxClicked {
    coffeeCheckboxSelected = !coffeeCheckboxSelected;
    [coffeeCheckbox setSelected:coffeeCheckboxSelected];
    if(allCategoriesCheckboxSelected) {
        allCategoriesCheckboxSelected = !allCategoriesCheckboxSelected;
        [allCategoriesCheckbox setSelected:allCategoriesCheckboxSelected];
    }
    [suggestionsTable reloadData];
}

-(void) hotelsCheckboxClicked {
    hotelsCheckboxSelected = !hotelsCheckboxSelected;
    [hotelsCheckbox setSelected:hotelsCheckboxSelected];
    if(allCategoriesCheckboxSelected) {
        allCategoriesCheckboxSelected = !allCategoriesCheckboxSelected;
        [allCategoriesCheckbox setSelected:allCategoriesCheckboxSelected];
    }
    [suggestionsTable reloadData];
}

-(void) gasCheckboxClicked {
    gasCheckboxSelected = !gasCheckboxSelected;
    [gasCheckbox setSelected:gasCheckboxSelected];
    if(allCategoriesCheckboxSelected) {
        allCategoriesCheckboxSelected = !allCategoriesCheckboxSelected;
        [allCategoriesCheckbox setSelected:allCategoriesCheckboxSelected];
    }
    [suggestionsTable reloadData];
}

-(void) atmCheckboxClicked {
    atmCheckboxSelected = !atmCheckboxSelected;
    [atmCheckbox setSelected:atmCheckboxSelected];
    if(allCategoriesCheckboxSelected) {
        allCategoriesCheckboxSelected = !allCategoriesCheckboxSelected;
        [allCategoriesCheckbox setSelected:allCategoriesCheckboxSelected];
    }
    [suggestionsTable reloadData];
}

-(void) searchAllCategories{
    [currentlySelectedCategories addObject:@"food"];
    [currentlySelectedCategories addObject:@"coffee shop"];
    [currentlySelectedCategories addObject:@"hotel"];
    [currentlySelectedCategories addObject:@"gas station"];
    [currentlySelectedCategories addObject:@"atm"];
    categoriesSearchOnly = YES;
    categoriesTable.hidden = YES;
    [self startGeocoding];
}

-(void) searchAllRestaurants{
    [currentlySelectedCategories addObject:@"food"];
    categoriesSearchOnly = YES;
    categoriesTable.hidden = YES;
    [self startGeocoding];
}

-(void) searchAllCoffee{
    [currentlySelectedCategories addObject:@"coffee shop"];
    categoriesSearchOnly = YES;
    categoriesTable.hidden = YES;
    [self startGeocoding];
}

-(void) searchAllGas{
    [currentlySelectedCategories addObject:@"gas station"];
    categoriesSearchOnly = YES;
    categoriesTable.hidden = YES;
    [self startGeocoding];
}

-(void) searchAllHotels{
    [currentlySelectedCategories addObject:@"hotel"];
    categoriesSearchOnly = YES;
    categoriesTable.hidden = YES;
    [self startGeocoding];
}

-(void) searchAllAtms{
    [currentlySelectedCategories addObject:@"atm"];
    categoriesSearchOnly = YES;
    categoriesTable.hidden = YES;
    [self startGeocoding];
}

@end
