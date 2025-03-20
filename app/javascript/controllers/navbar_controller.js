import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["mobileMenu", "mobileMenuButton", "openIcon", "closeIcon"]

  connect() {
    // Ensure menu is hidden on connect
    if (this.hasMobileMenuTarget) {
      this.mobileMenuTarget.classList.add("hidden")
    }
  }

  toggleMenu() {
    if (this.hasMobileMenuTarget) {
      this.mobileMenuTarget.classList.toggle("hidden")
      
      // Toggle visibility of the icons if targets exist
      if (this.hasOpenIconTarget && this.hasCloseIconTarget) {
        this.openIconTarget.classList.toggle("hidden")
        this.closeIconTarget.classList.toggle("hidden")
      }
    }
  }
} 