//
//  ViewController.swift
//  myLocation
//
//  Created by Boocha on 14.04.17.
//  Copyright © 2017 Boocha. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class ViewController: UIViewController, CLLocationManagerDelegate{
    
    //MAP
    @IBOutlet weak var nearestZastavkaLabel: UILabel!
    @IBOutlet weak var konecna1: UILabel!
    @IBOutlet weak var konecna2: UILabel!
    @IBOutlet weak var cas11: UILabel!
    @IBOutlet weak var cas12: UILabel!
    @IBOutlet weak var cas13: UILabel!
    @IBOutlet weak var cas21: UILabel!
    @IBOutlet weak var cas22: UILabel!
    @IBOutlet weak var cas23: UILabel!
    @IBOutlet weak var kontrolniMetroLabl: UILabel!
    
    
    
    var currentLocation = CLLocation()
    //globalni promenna, kam si vlozim soucasnou pozici ve fci location manager
    
    let manager = CLLocationManager()
    //první proměnná nutná pro práci s polohovým službama
    
    override func viewDidLoad() {
    //co se stane po loadnutí
        super.viewDidLoad()
        
        ////   LOKACE   ////
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest //nejlepší možná přesnost
        manager.requestWhenInUseAuthorization() //hodí request na užívání
        manager.startUpdatingLocation() //updatuje polohu
        
        
        /// Funkce pro plneni DB///
        //parseCSV(fileName: "mhd_final_data_utf8") //rozparsuje csv do formátu [["key":"value","key":"value"], ["key":"value"]]
        //fillData(csvFileName: "mhd_final_data_utf8", entityName: "FullEntity")
        //deleteDB(entityName: "FullEntity")
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    //vrátí aktuální polohu a vykreslí ji do mapy, všechny vykomentarovany veci se vztahuji k mape, kterou jsem odstranil
        let location = locations[0]//všechny lokace budou v tomto array, dostanu tu nejnovější
        
        currentLocation = location
        
        
        //// V PŘÍPADĚ, ŽE CHCI VYKRESLIT MAPU /////
        
        //let span: MKCoordinateSpan = MKCoordinateSpanMake(0.01, 0.01) //určuje, jak moc chci, aby byla mapa zoomnuta
        //let myLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude) //moje poloha
        
        //let myLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(50.076286, 14.446349)
        
        //let region: MKCoordinateRegion = MKCoordinateRegionMake(myLocation, span) //zkombinuje předchozí dvě vars a vytvoří region
        //map.setRegion(region, animated: true) //vykreslí mapu
        
        //self.map.showsUserLocation = true //vykreslí modrou tečku na místo, kde jsem
        
        nearestZastavkaLabel.text = nearestMetro()
        let metro_data = get_metro_times()
        
        konecna1.text = String(describing: metro_data[0][2])
        konecna2.text = String(describing: metro_data[3][2])
        cas11.text = formatTime(time: metro_data[0][1] as! Int)
        cas21.text = formatTime(time: metro_data[3][1] as! Int)
        
        cas12.text = formatTime(time: metro_data[1][1] as! Int)
        cas22.text = formatTime(time: metro_data[4][1] as! Int)
        
        cas13.text = formatTime(time: metro_data[2][1] as! Int)
        cas23.text = formatTime(time: metro_data[5][1] as! Int)
    }
    
    func nearestMetro() -> String{
    //vrátí název zastávky nejbližšího metra
        var lowest_distance: Double = 999999999999.99999
        var nearestZastavka = String()
        
        for (jmeno_zastavky, lokace_zastavky) in zastavky{
            let poloha_zastavky = CLLocation(latitude: lokace_zastavky[0], longitude: lokace_zastavky[1])
            let temporary_distance = currentLocation.distance(from: poloha_zastavky)
            if temporary_distance < lowest_distance{
                lowest_distance = temporary_distance
                nearestZastavka = jmeno_zastavky
            }
        }
    return nearestZastavka
    }


    
//////////// CORE DATA by Swift Guy ///////////
    
    func fillData(csvFileName: String, entityName: String){
    //naplní data z csv do DB
        
        let coreDataStack = CoreDataStack()
        //object ze souboru coredatastack
        let context = coreDataStack.persistentContainer.viewContext
        //objekt contex, na kterej se odvolavam
        
        let hodnoty = parseCSV(fileName: csvFileName)
        
        for hodnota in hodnoty{
            let novaPolozka = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
            
            for (key, value) in hodnota{
                
                if let cislo = Int(value){
                    novaPolozka.setValue(cislo, forKey: key)
                }else{
                    novaPolozka.setValue(value, forKey: key)
                }
            }
        }
        
        do{
            try context.save()
            print("SAVED")
        }catch{
            print("ANI PRD")
        }
    }
    
        // FETCHING RESULTS FROM CORE DATA - Swift Guy
         
    func fetchData(station_id: String, service_id: Int, results_count: Int, current_time: Int) -> [[Any]]{
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "FullEntity")
        //vytvoření kominikacniho objectu a zadání názvu entity
        
        var final_data = [[Any]]()
        //tohle to nakonec vrátí
        
        let coreDataStack = CoreDataStack()
        
        request.returnsObjectsAsFaults = false
        //pokud je to false, nereturnuju to fetchnuty data jako faults .. faults znamena, ze to napise misto konkretnich dat jen data = faults. Setri to pamet.
        
        let context = coreDataStack.persistentContainer.viewContext

        
        //PREDICATES a SORTDESCRIPTORS
        let current_time = current_time
        let station_id = station_id
        let schedule_id = service_id
        
        
        let myPredicate = NSPredicate(format: "stop_id == %@ AND service_id == %i AND arrival_time > %i", station_id, schedule_id, current_time)
        // pro string pouziju %@, integer %i, key %K
        
        let mySortDescriptor = NSSortDescriptor(key: "arrival_time", ascending: true)
        //seradi fetch data podle casu smerem nahoru
        request.predicate = myPredicate
        request.sortDescriptors = [mySortDescriptor]
        //přiřadí predicate a sortdescriptor do requestu, descriptoru muze byt vice, proto je to array
        
        do{
            let results = try context.fetch(request)
            
            if results.count > 0{
                
                for result in results as! [NSManagedObject]
                {
                    var single_array = [Any]()

                    if let stop_id = result.value(forKey: "stop_id") as? String, let arrival_time = result.value(forKey: "arrival_time") as? Int, let trip_headsign = result.value(forKey: "trip_headsign") as? String{
                        single_array.append(stop_id)
                        single_array.append(arrival_time)
                        single_array.append(trip_headsign)
                        //přiřadí values do array
                    }
                    final_data.append(single_array)
                    //přiřadí single array do konečného arraye
                    
                    if final_data.count > results_count - 1{
                        break
                        //díky tomuto to vrátí jen požadovaný počet výsledků
                    }
                }
            }
            
        }catch{
            print("Nepodařil se fetch")
        }
        return final_data
        }
    
    
    func deleteDB(entityName: String) {
        //Vymaže všechna data v dané položce
        let coreDataStack = CoreDataStack()
        let context = coreDataStack.persistentContainer.viewContext
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        do{
        try context.execute(request)
            print("Databáze vymazána")
        }catch{
            print(error)
        }
    }
    
    func current_time() -> Int{
    //vrátísoučasný čas jako Int
        let date = NSDate()
        let calendar = NSCalendar.current
        let hour = calendar.component(.hour, from: date as Date)
        var minutes = String(calendar.component(.minute, from: date as Date))
        if minutes.characters.count == 1{
            minutes = "0" + minutes
        }
        var seconds = String(calendar.component(.second, from: date as Date))
        if seconds.characters.count == 1{
            seconds = "0" + seconds
        }
        let final = Int("\(hour)\(minutes)\(seconds)")
        return final!
    }
    
    func get_metro_times() -> [[Any]]{
        //vrátí array s dvěma konecnyma a sesti casama
        let nearest_station = nearestMetro()
        //název zastávky metra
        let station_ids = stations_ids[nearest_station]!
        //dva ID kody pro danou zastavku a dvě konecne
        let time = current_time()
        //soucasny cas jako INT
    
        let times1 = fetchData(station_id: station_ids[0], service_id: 1, results_count: 3, current_time: time)
        let times2 = fetchData(station_id: station_ids[1], service_id: 1, results_count: 3, current_time: time)
        
        let times = times1 + times2
        
        //print(times)
        return times
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func formatTime(time: Int) -> String{
    //vezme cas v INT a preklopi ho do stringu s dvojteckama
        var time = String(describing: time)
        
        let index = time.index(time.endIndex, offsetBy: -2)
        time.insert(":", at: index)
        let index2 = time.index(time.endIndex, offsetBy: -5)
        time.insert(":", at: index2)
        
        return time

    }
    
    func parseCSV(fileName: String) -> [Dictionary<String, String>]{
    //rozparsuje SCVecko a vrátí array plnej dictionaries, kde key je název sloupce a value je hodnota
        let path = Bundle.main.path(forResource: fileName, ofType: "csv")
        var rows = [Dictionary<String, String>]()
        do {
            let csv = try CSV(contentsOfURL: path!)
            rows = csv.rows
            print(rows)
            //print(rows)
        }catch{
        print(error)
        }
        return rows
    }
    

    func getDocumentsDirectory() -> URL {
        //Vypíše cestu do dokumentu
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        print("Tohle je cesta dle funkce ve VC:  \(documentsDirectory)")
        return documentsDirectory
    }
    
    
    }

