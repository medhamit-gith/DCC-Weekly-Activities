//
//  WhatIfCoachingTipsTests.swift
//  DCC-Weekly-Activities Tests
//
//  SCRUM-89: coaching tips carry a what-if projection, so the "WHAT IF?"
//  section of CoachingTipCard has something to show.
//

import Testing
import Foundation
@testable import DCC_Weekly_Activities

@MainActor
@Suite("What-If Coaching Tips Tests")
struct WhatIfCoachingTipsTests {

    private func ride(
        _ member: String,
        km: Double,
        speed: Double = 25,
        seconds: Int = 3600
    ) -> Activity {
        Activity(
            memberName: member,
            activityName: "Ride",
            distance: km,
            date: Date(),
            averageSpeed: speed,
            elevationGain: 0,
            movingTime: seconds
        )
    }

    private func viewModel(_ stats: [MemberStats]) -> InsightsViewModel {
        let viewModel = InsightsViewModel()
        viewModel.stats = stats
        return viewModel
    }

    private func isClose(_ a: Double, _ b: Double) -> Bool {
        abs(a - b) < 0.001
    }

    @Test("Distance tip projects the rides needed to catch the leader")
    func distanceTipWithinReach() async throws {
        let leader = MemberStats(memberName: "Asha K.", activities: [
            ride("Asha K.", km: 60), ride("Asha K.", km: 60)
        ])
        let rider = MemberStats(memberName: "Ben T.", activities: [
            ride("Ben T.", km: 40), ride("Ben T.", km: 40)
        ])

        let tips = viewModel([leader, rider]).generateCoachingTips(for: rider)

        #expect(tips.count == 1)
        let whatIf = try #require(tips.first?.whatIf)
        #expect(whatIf.scenario == "If you ride 1 more time this week")
        #expect(isClose(whatIf.distanceGain, 40))
        #expect(isClose(whatIf.projectedDistance, 120))
    }

    @Test("A rider far behind is shown one more ride, not an unrealistic count")
    func distanceTipFarBehind() async throws {
        let leader = MemberStats(memberName: "Asha K.", activities: [
            ride("Asha K.", km: 100), ride("Asha K.", km: 100), ride("Asha K.", km: 100)
        ])
        let rider = MemberStats(memberName: "Ben T.", activities: [
            ride("Ben T.", km: 20)
        ])

        let tips = viewModel([leader, rider]).generateCoachingTips(for: rider)

        #expect(tips.count == 2)
        for tip in tips {
            let whatIf = try #require(tip.whatIf)
            #expect(whatIf.scenario == "If you ride 1 more time this week")
            #expect(isClose(whatIf.distanceGain, 20))
            #expect(isClose(whatIf.projectedDistance, 40))
        }
    }

    @Test("Ride-count tip projects the missing rides at the rider's average distance")
    func rideCountTip() async throws {
        let leader = MemberStats(memberName: "Asha K.", activities: [
            ride("Asha K.", km: 10), ride("Asha K.", km: 10), ride("Asha K.", km: 10),
            ride("Asha K.", km: 10), ride("Asha K.", km: 10)
        ])
        let rider = MemberStats(memberName: "Ben T.", activities: [
            ride("Ben T.", km: 48)
        ])

        let tips = viewModel([leader, rider]).generateCoachingTips(for: rider)

        let whatIf = try #require(tips.first?.whatIf)
        #expect(whatIf.scenario == "If you ride 4 more times this week")
        #expect(isClose(whatIf.distanceGain, 192))
    }

    @Test("Speed tip projects the extra distance over the same riding time")
    func speedTip() async throws {
        let leader = MemberStats(memberName: "Asha K.", activities: [
            ride("Asha K.", km: 30, speed: 35)
        ])
        let rider = MemberStats(memberName: "Ben T.", activities: [
            ride("Ben T.", km: 29.5, speed: 20, seconds: 5400)
        ])

        let tips = viewModel([leader, rider]).generateCoachingTips(for: rider)

        let whatIf = try #require(tips.first?.whatIf)
        #expect(whatIf.scenario == "Riding 2.0 km/h faster")
        #expect(isClose(whatIf.distanceGain, 3.0))
        #expect(isClose(whatIf.projectedDistance, 32.5))
    }

    @Test("The leader's own tip has no what-if")
    func leaderHasNoWhatIf() async throws {
        let leader = MemberStats(memberName: "Asha K.", activities: [ride("Asha K.", km: 60)])
        let rider = MemberStats(memberName: "Ben T.", activities: [ride("Ben T.", km: 40)])

        let tips = viewModel([leader, rider]).generateCoachingTips(for: leader)

        #expect(tips.count == 1)
        #expect(tips.first?.whatIf == nil)
    }

    @Test("A rider with no rides is not shown a +0km projection")
    func noRidesNoWhatIf() async throws {
        let leader = MemberStats(memberName: "Asha K.", activities: [ride("Asha K.", km: 60)])
        let rider = MemberStats(memberName: "Ben T.", activities: [])

        let tips = viewModel([leader, rider]).generateCoachingTips(for: rider)

        #expect(!tips.isEmpty)
        for tip in tips {
            #expect(tip.whatIf == nil)
        }
    }

    @Test("Faster-pace gain is the extra speed times the hours ridden")
    func fasterPaceGain() async throws {
        // A short fast ride and a long slow one: the mean of the two ride
        // speeds (25 km/h) is well above the rider's true overall pace.
        let rider = RiderStats(
            id: "Ben_T.",
            displayName: "Ben T.",
            firstname: "Ben",
            lastname: "T.",
            activities: [
                ride("Ben T.", km: 10, speed: 30, seconds: 1200),
                ride("Ben T.", km: 100, speed: 20, seconds: 18000)
            ]
        )

        let result = WhatIfEngine.whatIfFasterPace(extraKmh: 2, rider: rider)

        #expect(isClose(result.distanceGain, 2.0 * 19200.0 / 3600.0))
        #expect(isClose(result.projectedDistance, 110 + 2.0 * 19200.0 / 3600.0))
    }
}
