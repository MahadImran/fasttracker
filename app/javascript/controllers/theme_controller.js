import { Controller } from "@hotwired/stimulus"

const STORAGE_KEY = "fasttracker-theme"

export default class extends Controller {
  static targets = ["toggleLabel", "checkbox"]

  connect() {
    const storedTheme = window.localStorage.getItem(STORAGE_KEY)
    const preferredDark = window.matchMedia("(prefers-color-scheme: dark)").matches
    const theme = storedTheme || (preferredDark ? "night" : "dawn")

    this.applyTheme(theme)
  }

  toggle() {
    this.applyTheme(this.element.dataset.themeValue === "night" ? "dawn" : "night")
  }

  toggleFromInput(event) {
    this.applyTheme(event.target.checked ? "night" : "dawn")
  }

  applyTheme(theme) {
    this.element.dataset.themeValue = theme
    document.documentElement.dataset.theme = theme
    window.localStorage.setItem(STORAGE_KEY, theme)

    if (this.hasCheckboxTarget) {
      this.checkboxTarget.checked = theme === "night"
    }

    if (this.hasToggleLabelTarget) {
      this.toggleLabelTarget.textContent = theme === "night" ? "Night mode" : "Dawn mode"
    }
  }
}
