// Copyright (c) 2019 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/io;

public type CompoundPatternProcessor object {
    *AbstractPatternProcessor;
    *AbstractOperatorProcessor;
    public AbstractPatternProcessor? processor;
    public StreamEvent?[] fulfilledEvents;

    public function __init() {
        self.prevProcessor = ();
        self.stateEvents = new;
        self.processor = ();
        self.fulfilledEvents = [];
    }

    public function process(StreamEvent event, string? processorAlias) returns boolean {
        io:println("CompoundPatternProcessor:process:33 -> ", event, "|", processorAlias);
        boolean promote = false;
        boolean promoted = false;
        // downward traversal
        AbstractPatternProcessor? processor = self.processor;
        if (processor is AbstractPatternProcessor) {
            // processorAlias is not required when get promoted by
            // its only imidiate descendent. Therefore passing ().
            io:println("CompoundPatternProcessor:process:41 -> ", event, "|", processorAlias);
            promote = processor.process(event, ());
            io:println("CompoundPatternProcessor:process:43 -> ", event, "|", processorAlias);
        }
        // upward traversal
        if (promote) {
            AbstractOperatorProcessor? pProcessor = self.prevProcessor;
            if (pProcessor is AbstractOperatorProcessor) {
                self.stateEvents.resetToFront();
                while (self.stateEvents.hasNext()) {
                    StreamEvent s = getStreamEvent(self.stateEvents.next());
                    self.stateEvents.removeCurrent();
                    io:println("CompoundPatternProcessor:process:53 -> ", s, "|", processorAlias);
                    pProcessor.promote(s, processorAlias);
                    io:println("CompoundPatternProcessor:process:55 -> ", s, "|", processorAlias);
                    promoted = true;
                }
            } else {
                // pProcessor is (). Meaning, this is the root of the
                // pattern topology. So, emit events at the end of traversal.
                self.stateEvents.resetToFront();
                while (self.stateEvents.hasNext()) {
                    StreamEvent s = getStreamEvent(self.stateEvents.next());
                    self.stateEvents.removeCurrent();
                    io:println("CompoundPatternProcessor:process:65 -> ", s, "|", processorAlias);
                    self.emit(s);
                    promoted = true;
                }
            }
        }
        io:println("CompoundPatternProcessor:process:71 -> ", event, "|", processorAlias);
        return promoted;
    }

    public function promote(StreamEvent stateEvent, string? processorAlias) {
        io:println("CompoundPatternProcessor:promote:76 -> ", stateEvent, "|", processorAlias);
        self.stateEvents.addLast(stateEvent);
    }

    public function emit(StreamEvent stateEvent) {
        io:println("CompoundPatternProcessor:emit:81 -> ", stateEvent);
        self.fulfilledEvents[self.fulfilledEvents.length()] = stateEvent;
    }

    public function flushAndGetFulfilledEvents() returns StreamEvent?[] {
        StreamEvent?[] evts = self.fulfilledEvents;
        self.fulfilledEvents = [];
        return evts;
    }

    public function setPreviousProcessor(AbstractOperatorProcessor processor) {
        self.prevProcessor = processor;
    }

    public function setProcessor(AbstractPatternProcessor processor) {
        self.processor = processor;
        self.processor.setPreviousProcessor(self);
    }

    public function getAlias() returns string {
        string alias = "(";
        AbstractPatternProcessor? pProcessor = self.processor;
        if (pProcessor is AbstractPatternProcessor) {
            alias = alias + pProcessor.getAlias();
        }
        alias = alias + ")";
        return alias;
    }
};

public function createCompoundPatternProcessor() returns CompoundPatternProcessor {
    CompoundPatternProcessor compoundPatternProcessor = new;
    return compoundPatternProcessor;
}