// Example usage:
//
// import { MyShape } from ./myShape.js;
//
// class MyComponent extends React.Component {
//   //
// }
//
// MyComponent.propTypes = {
//   input: MyShape
// };

import PropTypes from "prop-types";

let _Test;
let _Convert;
_Convert = PropTypes.shape({
});
_Test = PropTypes.shape({
    "asdf": PropTypes.string,
    "asdf2": PropTypes.string,
});

export const Test = _Test;

export const Convert = _Convert;
