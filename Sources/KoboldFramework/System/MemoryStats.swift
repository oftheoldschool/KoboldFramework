import Foundation
import Metal
import Darwin

public struct KMemoryStats {
    public var appUsedBytes: UInt64
    public var appAvailableBytes: UInt64
    public var gpuAllocatedBytes: UInt64
    public var gpuBudgetBytes: UInt64

    public var appLimitBytes: UInt64 {
        appUsedBytes &+ appAvailableBytes
    }

    public static func current(device: MTLDevice) -> KMemoryStats {
        return KMemoryStats(
            appUsedBytes: sampleAppUsedBytes(),
            appAvailableBytes: sampleAppAvailableBytes(),
            gpuAllocatedBytes: UInt64(device.currentAllocatedSize),
            gpuBudgetBytes: UInt64(device.recommendedMaxWorkingSetSize))
    }

    private static func sampleAppUsedBytes() -> UInt64 {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { ptr -> kern_return_t in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), intPtr, &count)
            }
        }
        guard result == KERN_SUCCESS else { return 0 }
        return UInt64(info.phys_footprint)
    }

    private static func sampleAppAvailableBytes() -> UInt64 {
        return UInt64(os_proc_available_memory())
    }
}
