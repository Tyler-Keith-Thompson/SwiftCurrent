//
//  WorkflowTests.swift
//  
//
//  Created by Tyler Thompson on 5/1/21.
//  Copyright © 2021 WWT and Tyler Thompson. All rights reserved.
//

import Foundation
import XCTest

@testable import Workflow

class WorkflowTests: XCTestCase {
    func testFlowRepresentablesWithMultipleTypesCanBeStoredAndRetrieved() {
        struct FR1: FlowRepresentable {
            typealias WorkflowOutput = Int
            static var shouldLoadCalledOnFR1 = false

            weak var _workflowPointer: AnyFlowRepresentable?

            init(with args: String) { }

            func shouldLoad(with args: String) -> Bool {
                FR1.shouldLoadCalledOnFR1 = true
                return true
            }
        }
        struct FR2: FlowRepresentable {
            static var shouldLoadCalledOnFR2 = false

            weak var _workflowPointer: AnyFlowRepresentable?

            init(with args: Int) { }

            func shouldLoad(with args: Int) -> Bool {
                FR2.shouldLoadCalledOnFR2 = true
                return true
            }
        }
        let flow = Workflow(FR1.self).thenPresent(FR2.self)
        let first = flow.first?.value.flowRepresentableFactory(.args("str"))
        let last = flow.last?.value.flowRepresentableFactory(.args(1))
        _ = first?.shouldLoad(with: "str")
        _ = last?.shouldLoad(with: 1)

        XCTAssert(FR1.shouldLoadCalledOnFR1, "Should load not called on flow representable 1 with correct corresponding type")
        XCTAssert(FR2.shouldLoadCalledOnFR2, "Should load not called on flow representable 2 with correct corresponding type")
    }

    func testFlowRepresentablesThatDefineAWorkflowInputOfOptionalAnyDoesNotRecurseForever() {
        class FR1: FlowRepresentable {
            static var shouldLoadCalledOnFR1 = false

            weak var _workflowPointer: AnyFlowRepresentable?

            required init(with args: Any?) { }
        }

        let instance = AnyFlowRepresentable(FR1.self, args: .args("str"))
        XCTAssert(instance.shouldLoad(with: "str") == true)
    }

    func testAnyFlowRepresentableThrowsFatalErrorIfItSomehowHasATypeMismatch() {
        class FR1: TestFlowRepresentable<String, Int>, FlowRepresentable {
            required init(with args: String) { }
        }

        let rep = AnyFlowRepresentable(FR1.self, args: .args(""))

        XCTAssertThrowsFatalError {
            _ = rep.shouldLoad(with: 10.23)
        }
    }

    func testFlowRepresentableThrowsFatalErrorIfNoCustomEmptyInitSupplied() {
        class FR1: FlowRepresentable {
            weak var _workflowPointer: AnyFlowRepresentable?

            required init(with name:String) { }
        }

        XCTAssertThrowsFatalError {
            _ = FR1()
        }
    }

    func testFlowRepresentableThrowsFatalError_IfShouldLoadIsCalledWithNoArguments_AndWorkflowHasInput() {
        class FR1: FlowRepresentable {
            weak var _workflowPointer: AnyFlowRepresentable?

            required init(with name:String) { }
        }

        XCTAssertThrowsFatalError {
            var fr1 = FR1(with: "")
            _ = fr1.shouldLoad()
        }
    }

    func testAnyWorkflowThrowsFatalErrorWhenMetadataGetsMangledOnProceed() {
        final class FR1: FlowRepresentable {
            typealias WorkflowInput = Never
            weak var _workflowPointer: AnyFlowRepresentable?
        }

        XCTAssertThrowsFatalError {
            let wf = Workflow(FR1.self)
            wf.removeAll()
            (wf.instances.first?.value?.underlyingInstance as! FR1).proceedInWorkflow()
            wf.launch()
        }
    }
}

extension WorkflowTests {
    class TestFlowRepresentable<I, O> {
        typealias WorkflowInput = I
        typealias WorkflowOutput = O

        weak var _workflowPointer: AnyFlowRepresentable?
    }
}

