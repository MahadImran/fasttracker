import { Controller } from "@hotwired/stimulus"

const ISLAMIC_EPOCH = 1948439

export default class extends Controller {
  static targets = ["gregorian", "hijri"]

  connect() {
    if (this.hasGregorianTarget) {
      this.gregorianTarget.dataset.autoValue = this.gregorianTarget.value.trim()
    }

    if (this.hasHijriTarget) {
      this.hijriTarget.dataset.autoValue = this.hijriTarget.value.trim()
    }
  }

  syncFromGregorian() {
    if (!this.hasGregorianTarget || !this.hasHijriTarget) return

    const gregorianYear = this.parseYear(this.gregorianTarget.value)
    const currentHijriYear = this.hijriTarget.value.trim()
    const lastAutoHijriYear = this.hijriTarget.dataset.autoValue

    if (gregorianYear === null) {
      if (currentHijriYear !== "" && currentHijriYear === lastAutoHijriYear) {
        this.hijriTarget.value = ""
        delete this.hijriTarget.dataset.autoValue
      }
      return
    }

    if (currentHijriYear !== "" && currentHijriYear !== lastAutoHijriYear) return

    const nextHijriYear = String(this.estimatedHijriYearFor(gregorianYear))
    this.hijriTarget.value = nextHijriYear
    this.hijriTarget.dataset.autoValue = nextHijriYear
  }

  syncFromHijri() {
    if (!this.hasGregorianTarget || !this.hasHijriTarget) return

    const hijriYear = this.parseYear(this.hijriTarget.value)
    const currentGregorianYear = this.gregorianTarget.value.trim()
    const lastAutoGregorianYear = this.gregorianTarget.dataset.autoValue

    if (hijriYear === null) {
      if (currentGregorianYear !== "" && currentGregorianYear === lastAutoGregorianYear) {
        this.gregorianTarget.value = ""
        delete this.gregorianTarget.dataset.autoValue
      }
      return
    }

    if (currentGregorianYear !== "" && currentGregorianYear !== lastAutoGregorianYear) return

    const nextGregorianYear = String(this.estimatedGregorianYearFor(hijriYear))
    this.gregorianTarget.value = nextGregorianYear
    this.gregorianTarget.dataset.autoValue = nextGregorianYear
  }

  parseYear(value) {
    const year = parseInt(value, 10)
    return Number.isNaN(year) ? null : year
  }

  estimatedGregorianYearFor(hijriYear) {
    return this.ramadanStartFor(hijriYear).getUTCFullYear()
  }

  estimatedHijriYearFor(gregorianYear) {
    for (let candidate = gregorianYear - 580; candidate <= gregorianYear - 578; candidate += 1) {
      if (this.ramadanStartFor(candidate).getUTCFullYear() === gregorianYear) {
        return candidate
      }
    }

    return gregorianYear - 579
  }

  ramadanStartFor(hijriYear) {
    const daysBeforeRamadan = Math.ceil(29.5 * 8)
    const julianDay = 1 + daysBeforeRamadan + ((hijriYear - 1) * 354) + Math.floor((3 + (11 * hijriYear)) / 30) + ISLAMIC_EPOCH - 1
    return this.gregorianDateFromJulianDay(julianDay)
  }

  gregorianDateFromJulianDay(julianDay) {
    let l = julianDay + 68569
    const n = Math.floor((4 * l) / 146097)
    l -= Math.floor((146097 * n + 3) / 4)
    const i = Math.floor((4000 * (l + 1)) / 1461001)
    l = l - Math.floor((1461 * i) / 4) + 31
    const j = Math.floor((80 * l) / 2447)
    const day = l - Math.floor((2447 * j) / 80)
    l = Math.floor(j / 11)
    const month = j + 2 - (12 * l)
    const year = 100 * (n - 49) + i + l

    return new Date(Date.UTC(year, month - 1, day))
  }
}
