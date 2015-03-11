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

#import "ResultsViewController.h"


@implementation ResultsViewController

// in iOS7 this gets called and hides the status bar so the view does not go under the top iPhone status bar
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (IBAction)done:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //if results is not nil and we have results, return that number
    return ((self.results != nil && [self.results count] > 0) ? [self.results count] : 0);
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // Set up the cell...
    
    //text is the key at the given indexPath
    NSString *keyAtIndexPath = [self.results allKeys][indexPath.row];
    cell.textLabel.text = keyAtIndexPath;
    
    //detail text is the value associated with the key above
    id detailValue = (self.results)[keyAtIndexPath];
    
    //figure out if the value is a NSDecimalNumber or NSString
    if ([detailValue isKindOfClass:[NSString class]])
     {
         //value is a NSString, just set it
         cell.detailTextLabel.text = (NSString *)detailValue;
     }
    else if ([detailValue isKindOfClass:[NSDecimalNumber class]])
    {
        //value is a NSDecimalNumber, format the result as a double
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%0.0f", [detailValue doubleValue]];
    }
    else {
        //not a NSDecimalNumber or a NSString, 
        cell.detailTextLabel.text = @"N/A";
    }
	
    return cell;
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (YES);
}



@end

