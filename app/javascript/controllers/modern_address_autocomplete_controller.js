import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["field", "results", "placeId", "latitude", "longitude"]
  static values = {
    minLength: { type: Number, default: 3 },
    debounce: { type: Number, default: 300 }
  }

  initialize() {
    // Create a debouncer function to avoid too many API requests
    this.debouncedSearch = this.debounce(this.fetchSuggestions.bind(this), this.debounceValue)
    this.selectedIndex = -1
    this.suggestions = []
    this.clickOutsideHandler = this.clickOutside.bind(this)
  }
  
  connect() {
    // Hide results initially
    this.hideResults()
    
    // Set up click outside handler
    document.addEventListener('click', this.clickOutsideHandler)
  }
  
  disconnect() {
    // Clean up event listeners
    document.removeEventListener('click', this.clickOutsideHandler)
  }
  
  // Input event handler
  search() {
    const query = this.fieldTarget.value.trim()
    
    if (query.length < this.minLengthValue) {
      this.hideResults()
      return
    }
    
    this.debouncedSearch(query)
  }
  
  // Fetch suggestions from our API controller
  async fetchSuggestions(query) {
    try {
      const response = await fetch(`/places/autocomplete?query=${encodeURIComponent(query)}`)
      
      if (!response.ok) {
        throw new Error(`HTTP error ${response.status}`)
      }
      
      const data = await response.json()
      this.suggestions = data.predictions || []
      
      if (this.suggestions.length === 0) {
        this.hideResults()
        return
      }
      
      this.showResults()
    } catch (error) {
      console.error("Error fetching address suggestions:", error)
      this.hideResults()
    }
  }
  
  // Display the suggestions in a dropdown
  showResults() {
    if (!this.hasResultsTarget) return
    
    // Clear previous results
    this.resultsTarget.innerHTML = ''
    
    // Create the list of suggestions
    const ul = document.createElement('ul')
    ul.className = 'bg-white rounded-md shadow-md border border-gray-300 absolute z-10 w-full max-h-60 overflow-auto'
    
    this.suggestions.forEach((suggestion, index) => {
      const li = document.createElement('li')
      li.className = 'px-4 py-2 hover:bg-gray-100 cursor-pointer'
      li.innerHTML = `<div class="font-medium">${suggestion.name}</div>
                      <div class="text-sm text-gray-600">${suggestion.description}</div>`
      li.dataset.index = index
      li.addEventListener('click', () => this.selectSuggestion(index))
      ul.appendChild(li)
    })
    
    this.resultsTarget.appendChild(ul)
    this.resultsTarget.classList.remove('hidden')
  }
  
  // Hide the suggestions dropdown
  hideResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.innerHTML = ''
      this.resultsTarget.classList.add('hidden')
    }
    this.selectedIndex = -1
  }
  
  // Handle keyboard navigation
  keydown(event) {
    if (!this.hasResultsTarget || this.resultsTarget.classList.contains('hidden')) return
    
    const suggestionItems = this.resultsTarget.querySelectorAll('li')
    
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault()
        this.selectedIndex = Math.min(this.selectedIndex + 1, suggestionItems.length - 1)
        this.highlightSuggestion()
        break
        
      case 'ArrowUp':
        event.preventDefault()
        this.selectedIndex = Math.max(this.selectedIndex - 1, -1)
        this.highlightSuggestion()
        break
        
      case 'Enter':
        event.preventDefault()
        if (this.selectedIndex >= 0) {
          this.selectSuggestion(this.selectedIndex)
        }
        break
        
      case 'Escape':
        this.hideResults()
        break
    }
  }
  
  // Highlight the currently selected suggestion
  highlightSuggestion() {
    const items = this.resultsTarget.querySelectorAll('li')
    
    items.forEach((item, index) => {
      if (index === this.selectedIndex) {
        item.classList.add('bg-gray-100')
      } else {
        item.classList.remove('bg-gray-100')
      }
    })
    
    // Scroll to the selected item if needed
    if (this.selectedIndex >= 0) {
      const selectedItem = items[this.selectedIndex]
      selectedItem.scrollIntoView({ block: 'nearest' })
    }
  }
  
  // Select a suggestion and fill the input field
  selectSuggestion(index) {
    const suggestion = this.suggestions[index]
    if (!suggestion) return
    
    this.fieldTarget.value = suggestion.description
    
    // Fill the hidden fields with the place data
    if (this.hasPlaceIdTarget) {
      this.placeIdTarget.value = suggestion.place_id
    }
    
    if (this.hasLatitudeTarget) {
      this.latitudeTarget.value = suggestion.latitude
    }
    
    if (this.hasLongitudeTarget) {
      this.longitudeTarget.value = suggestion.longitude
    }
    
    this.hideResults()
    
    // Trigger change event to notify other components
    this.fieldTarget.dispatchEvent(new Event('change', { bubbles: true }))
  }
  
  // Handle clicks outside the component
  clickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }
  
  // Debounce helper function
  debounce(func, wait) {
    let timeout
    return function(...args) {
      clearTimeout(timeout)
      timeout = setTimeout(() => func.apply(this, args), wait)
    }
  }
} 