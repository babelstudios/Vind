//
//  Result.swift
//  Vind
//
//  Created by Jens Utbult on 2015-12-22.
//  Copyright © 2015 Jens Utbult. All rights reserved.
//

import Foundation

enum Result<T> {
    case Success(T)
    case Error(e: ErrorType)
}
