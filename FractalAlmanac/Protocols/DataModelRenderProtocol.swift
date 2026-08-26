//
//  DataModelRenderProtocol.swift
//  FractalAlmanac
//
//  Created by Martin Stoufer on 6/29/26.
//


protocol DataModelRenderProtocol: AnyObject {
    func renderingHasBegun()
    func renderingHasEnded()
    func updateRenderingProgress(progress:Float) async
    func precisionExtentsReached()
    func extentsHaveRefreshed() async throws
}
