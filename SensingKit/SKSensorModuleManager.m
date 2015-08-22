//
//  SKSensorModuleManager.m
//  SensingKit
//
//  Copyright (c) 2014. Queen Mary University of London
//  Kleomenis Katevas, k.katevas@qmul.ac.uk
//
//  This file is part of SensingKit-iOS library.
//  For more information, please visit http://www.sensingkit.org
//
//  SensingKit-iOS is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  SensingKit-iOS is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public License
//  along with SensingKit-iOS.  If not, see <http://www.gnu.org/licenses/>.
//

#import "SKSensorModuleManager.h"
#import "SKAbstractSensorModule.h"
#import "NSString+SensorModuleType.h"

// SensorModules
#import "SKBattery.h"
#import "SKLocation.h"
#import "SKiBeaconProximity.h"
#import "SKEddystoneProximity.h"
#import "SKAccelerometer.h"
#import "SKGyroscope.h"
#import "SKMagnetometer.h"
#import "SKDeviceMotion.h"
#import "SKActivity.h"

#define TOTAL_SENSOR_MODULES 9

@interface SKSensorModuleManager()

@property (nonatomic, strong, readonly) NSMutableArray *sensorModules;

@end


@implementation SKSensorModuleManager

- (instancetype)init
{
    if (self = [super init])
    {
        // init array that holds the sensor modules
        _sensorModules = [[NSMutableArray alloc] initWithCapacity:TOTAL_SENSOR_MODULES];
        
        for (NSInteger i = 0; i < TOTAL_SENSOR_MODULES; i++) {
            [_sensorModules addObject:[NSNull null]];
        }
    }
    return self;
}

#pragma mark Sensor Registration methods

- (void)registerSensorModule:(SKSensorModuleType)moduleType
{
    NSLog(@"Register sensor: %@.", [NSString stringWithSensorModuleType:moduleType]);
    
    if ([self isSensorModuleRegistered:moduleType]) {
        
        NSLog(@"SensorModule is already registered.");
        abort();
    }
    
    SKAbstractSensorModule *sensorModule = [self createSensorModule:moduleType];
    [self.sensorModules replaceObjectAtIndex:moduleType withObject:sensorModule];
}

- (void)deregisterSensorModule:(SKSensorModuleType)moduleType
{
    NSLog(@"Deregister sensor: %@.", [NSString stringWithSensorModuleType:moduleType]);
    
    if (![self isSensorModuleRegistered:moduleType]) {
        
        NSLog(@"SensorModule is not registered.");
        abort();
    }
    
    if ([self isSensorModuleSensing:moduleType]) {
        
        NSLog(@"SensorModule is currently sensing.");
        abort();
    }
    
    // Clear all Callbacks from that sensor
    [[self getSensorModule:moduleType] unsubscribeAllSensorDataListeners];
    
    // Deregister the SensorModule
    [self.sensorModules replaceObjectAtIndex:moduleType withObject:[NSNull null]];
}

- (BOOL)isSensorModuleRegistered:(SKSensorModuleType)moduleType
{
    return ([self.sensorModules objectAtIndex:moduleType] != [NSNull null]);
}


#pragma mark Continuous Sensing methods

- (void)subscribeSensorDataListenerToSensor:(SKSensorModuleType)moduleType
                                withHandler:(SKSensorDataHandler)handler {
    
    NSLog(@"Subscribe to sensor: %@.", [NSString stringWithSensorModuleType:moduleType]);
    
    [[self getSensorModule:moduleType] subscribeSensorDataListener:handler];
}

- (void)unsubscribeSensorDataListenerFromSensor:(SKSensorModuleType)moduleType
                                      ofHandler:(SKSensorDataHandler)handler
{
    NSLog(@"Unsubscribe from sensor: %@.", [NSString stringWithSensorModuleType:moduleType]);
    
    [[self getSensorModule:moduleType] unsubscribeSensorDataListener:handler];
}

- (void)unsubscribeAllSensorDataListeners:(SKSensorModuleType)moduleType
{
    NSLog(@"Unsubscribe from all sensors.");
    
    [[self getSensorModule:moduleType] unsubscribeAllSensorDataListeners];
}

- (void)startContinuousSensingWithSensor:(SKSensorModuleType)moduleType
{
    NSLog(@"Start sensing with sensor: %@.", [NSString stringWithSensorModuleType:moduleType]);
    
    if ([self isSensorModuleSensing:moduleType]) {
        
        NSLog(@"SensorModule '%@' is already sensing.", [NSString stringWithSensorModuleType:moduleType]);
        abort();
    }
    
    // Start Sensing
    [[self getSensorModule:moduleType] startSensing];
}

- (void)stopContinuousSensingWithSensor:(SKSensorModuleType)moduleType
{
    NSLog(@"Stop sensing with sensor: %@.", [NSString stringWithSensorModuleType:moduleType]);
    
    if (![self isSensorModuleSensing:moduleType]) {
        
        NSLog(@"SensorModule '%@' is already not sensing.", [NSString stringWithSensorModuleType:moduleType]);
        abort();
    }
    
    // Stop Sensing
    [[self getSensorModule:moduleType] stopSensing];
}

- (void)startContinuousSensingWithAllRegisteredSensors
{
    for (NSInteger i = 0; i < TOTAL_SENSOR_MODULES; i++) {
        
        SKSensorModuleType moduleType = i;
        
        if ([self isSensorModuleRegistered:moduleType]) {
            [self startContinuousSensingWithSensor:moduleType];
        }
    }
}

- (void)stopContinuousSensingWithAllRegisteredSensors
{
    for (NSInteger i = 0; i < TOTAL_SENSOR_MODULES; i++) {
        
        SKSensorModuleType moduleType = i;
        
        if ([self isSensorModuleRegistered:moduleType]) {
            [self stopContinuousSensingWithSensor:moduleType];
        }
    }
}

- (BOOL)isSensorModuleSensing:(SKSensorModuleType)moduleType
{
    return [[self getSensorModule:moduleType] isSensing];
}


- (SKAbstractSensorModule *)getSensorModule:(SKSensorModuleType)moduleType
{
    if (![self isSensorModuleRegistered:moduleType]) {
        
        NSLog(@"SensorModule '%@' is not registered.", [NSString stringWithSensorModuleType:moduleType]);
        abort();
    }
    
    return [self.sensorModules objectAtIndex:moduleType];
}

- (SKAbstractSensorModule *)createSensorModule:(SKSensorModuleType)moduleType
{
    SKAbstractSensorModule *sensorModule;
    
    switch (moduleType) {
            
        case Accelerometer:
            sensorModule = [[SKAccelerometer alloc] init];
            break;
            
        case Gyroscope:
            sensorModule = [[SKGyroscope alloc] init];
            break;
            
        case Magnetometer:
            sensorModule = [[SKMagnetometer alloc] init];
            break;
            
        case DeviceMotion:
            sensorModule = [[SKDeviceMotion alloc] init];
            break;
            
        case Activity:
            sensorModule = [[SKActivity alloc] init];
            break;
            
        case Battery:
            sensorModule = [[SKBattery alloc] init];
            break;
            
        case Location:
            sensorModule = [[SKLocation alloc] init];
            break;
            
        case iBeaconProximity:
            sensorModule = [[SKiBeaconProximity alloc] initWithUUID:[[NSUUID alloc] initWithUUIDString:@"d45a1046-15b0-11e5-b60b-1697f925ec7b"]
                                                          withMajor:arc4random_uniform(65535)    // Random Major
                                                          withMinor:arc4random_uniform(65535)];  // Random Minor
            break;
            
        case EddystoneProximity:
            sensorModule = [[SKEddystoneProximity alloc] initWithNamespace:@"2f234454f4911ba9ffa6"];
            break;
            
            // Don't forget to break!
            
        default:
            NSLog(@"Unknown SensorModule: %li", (long)moduleType);
            abort();
    }
    
    return sensorModule;
}

@end
