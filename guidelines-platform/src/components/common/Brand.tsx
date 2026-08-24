import { Link } from "react-router-dom";

export function Brand() {
  return (
    <Link className="brand" to="/" aria-label="Clinical Guidelines home">
      <img className="brand-mark" src="/coat_of_arms.png" alt="" aria-hidden="true" />
      <span>
        <strong>Clinical Guidelines</strong>
        <small>MediGuide</small>
      </span>
    </Link>
  );
}
