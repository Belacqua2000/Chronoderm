//
//  EntriesFlowLayout.swift
//  Chronoderm
//
//  Created by Nick Baughan on 25/03/2020.
//  Copyright © 2020 Nick Baughan. All rights reserved.
//

import UIKit

class EntriesFlowLayout: UICollectionViewFlowLayout {
    
    override func prepare() {
        super.prepare()
        
        guard let cv = collectionView else { return }
        
        // Methods below calculates the size of collection view items to ensure there is equal spacing between each item, no matter size
        let cvWidth = cv.bounds.inset(by: cv.layoutMargins).size.width - 50
        let minimumItemWidth: CGFloat = 120
        
        let maxNumberOfItems = Int(cvWidth / minimumItemWidth)
        
        let itemWidth = (cvWidth / CGFloat(maxNumberOfItems)).rounded(.down)
        let itemHeight = itemWidth * 1.5
        
        self.itemSize = CGSize(width: itemWidth, height: itemHeight)
        
        
    }
    
    
}
