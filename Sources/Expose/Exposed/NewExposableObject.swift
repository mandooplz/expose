import Observation

@available(iOS 17.0, *)
public protocol NewExposableObject: ExposableObject, Observation.Observable {
    var registrar: ObservationRegistrar { get }
}