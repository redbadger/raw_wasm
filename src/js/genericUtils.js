const typeOf   = x => Object.prototype.toString.apply(x).slice(8).slice(0, -1)
const isOfType = t => x => typeOf(x) === t
const isArray  = isOfType("Array")

// ---------------------------------------------------------------------------------------------------------------------
const setProperty = (obj, propName, propVal) => (_ => obj)(obj[propName] = propVal)

// ---------------------------------------------------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------------------------------------------------
export {
  isArray,
  setProperty,
}
