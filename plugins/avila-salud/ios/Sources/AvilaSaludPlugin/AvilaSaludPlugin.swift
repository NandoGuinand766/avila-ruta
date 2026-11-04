import Foundation
import Capacitor
import HealthKit
import CoreLocation

/// Lee de Apple Salud los entrenamientos (Apple Watch, Garmin Connect y otras apps que escriben en Salud),
/// con su recorrido GPS y el pulso, para transferirlos a Ávila Ruta.
@objc(AvilaSaludPlugin)
public class AvilaSaludPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "AvilaSaludPlugin"
    public let jsName = "AvilaSalud"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "isAvailable", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "requestAuthorization", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "recentWorkouts", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "workoutRoute", returnType: CAPPluginReturnPromise)
    ]

    private let store = HKHealthStore()
    private let heartRate = HKObjectType.quantityType(forIdentifier: .heartRate)!

    @objc func isAvailable(_ call: CAPPluginCall) {
        call.resolve(["available": HKHealthStore.isHealthDataAvailable()])
    }

    @objc func requestAuthorization(_ call: CAPPluginCall) {
        guard HKHealthStore.isHealthDataAvailable() else {
            call.reject("Apple Salud no está disponible en este dispositivo")
            return
        }
        let read: Set<HKObjectType> = [HKObjectType.workoutType(), HKSeriesType.workoutRoute(), heartRate]
        store.requestAuthorization(toShare: nil, read: read) { ok, error in
            if let error = error { call.reject(error.localizedDescription) } else { call.resolve(["granted": ok]) }
        }
    }

    /// Entrenamientos de los últimos `days` días (por defecto 60), del más reciente al más antiguo.
    @objc func recentWorkouts(_ call: CAPPluginCall) {
        let days = call.getInt("days") ?? 60
        let since = Calendar.current.date(byAdding: .day, value: -days, to: Date())
        let predicate = HKQuery.predicateForSamples(withStart: since, end: nil, options: [])
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: call.getInt("limit") ?? 30, sortDescriptors: [sort]) { _, samples, error in
            if let error = error { call.reject(error.localizedDescription); return }
            let list: [[String: Any]] = (samples as? [HKWorkout] ?? []).map { w in
                [
                    "id": w.uuid.uuidString,
                    "start": w.startDate.timeIntervalSince1970 * 1000,
                    "end": w.endDate.timeIntervalSince1970 * 1000,
                    "duration": w.duration,
                    "distance": w.totalDistance?.doubleValue(for: .meter()) ?? 0,
                    "activity": Self.activityName(w.workoutActivityType),
                    "source": w.sourceRevision.source.name
                ]
            }
            call.resolve(["workouts": list])
        }
        store.execute(query)
    }

    /// Recorrido GPS ([lat, lon, altitud, tiempo ms]) y pulso ([tiempo ms, ppm]) de un entrenamiento.
    @objc func workoutRoute(_ call: CAPPluginCall) {
        guard let idText = call.getString("id"), let uuid = UUID(uuidString: idText) else {
            call.reject("Falta el entrenamiento")
            return
        }
        let byId = HKQuery.predicateForObject(with: uuid)
        let find = HKSampleQuery(sampleType: .workoutType(), predicate: byId, limit: 1, sortDescriptors: nil) { [weak self] _, samples, error in
            guard let self = self else { return }
            guard let workout = samples?.first as? HKWorkout else {
                call.reject(error?.localizedDescription ?? "No se encontró el entrenamiento")
                return
            }
            self.loadRoute(workout) { points, routeError in
                if let routeError = routeError { call.reject(routeError); return }
                self.loadHeartRate(workout) { hr in
                    call.resolve(["points": points, "hr": hr, "duration": workout.duration])
                }
            }
        }
        store.execute(find)
    }

    private func loadRoute(_ workout: HKWorkout, done: @escaping ([[Double]], String?) -> Void) {
        let fromWorkout = HKQuery.predicateForObjects(from: workout)
        let routes = HKSampleQuery(sampleType: HKSeriesType.workoutRoute(), predicate: fromWorkout, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] _, samples, error in
            guard let self = self else { return }
            guard let route = (samples as? [HKWorkoutRoute])?.first else {
                done([], error?.localizedDescription ?? "Este entrenamiento no tiene recorrido GPS")
                return
            }
            var points: [[Double]] = []
            let read = HKWorkoutRouteQuery(route: route) { _, locations, finished, routeError in
                if let routeError = routeError { done([], routeError.localizedDescription); return }
                for l in locations ?? [] {
                    points.append([l.coordinate.latitude, l.coordinate.longitude, l.altitude, l.timestamp.timeIntervalSince1970 * 1000])
                }
                if finished { done(points, nil) }
            }
            self.store.execute(read)
        }
        store.execute(routes)
    }

    private func loadHeartRate(_ workout: HKWorkout, done: @escaping ([[Double]]) -> Void) {
        let during = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let bpm = HKUnit.count().unitDivided(by: .minute())
        let query = HKSampleQuery(sampleType: heartRate, predicate: during, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, _ in
            let list = (samples as? [HKQuantitySample] ?? []).map { [$0.startDate.timeIntervalSince1970 * 1000, $0.quantity.doubleValue(for: bpm)] }
            done(list)
        }
        store.execute(query)
    }

    private static func activityName(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .hiking: return "hiking"
        case .walking: return "walking"
        case .running: return "running"
        case .climbing: return "climbing"
        case .cycling: return "cycling"
        default: return "other"
        }
    }
}
