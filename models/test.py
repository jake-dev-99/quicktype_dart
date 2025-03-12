from typing import Any, TypeVar, Type, cast


T = TypeVar("T")


def from_str(x: Any) -> str:
    assert isinstance(x, str)
    return x


def to_class(c: Type[T], x: Any) -> dict:
    assert isinstance(x, c)
    return cast(Any, x).to_dict()


class Test:
    asdf: str
    asdf2: str

    def __init__(self, asdf: str, asdf2: str) -> None:
        self.asdf = asdf
        self.asdf2 = asdf2

    @staticmethod
    def from_dict(obj: Any) -> 'Test':
        assert isinstance(obj, dict)
        asdf = from_str(obj.get("asdf"))
        asdf2 = from_str(obj.get("asdf2"))
        return Test(asdf, asdf2)

    def to_dict(self) -> dict:
        result: dict = {}
        result["asdf"] = from_str(self.asdf)
        result["asdf2"] = from_str(self.asdf2)
        return result


class Convert:
    pass

    def __init__(self, ) -> None:
        pass

    @staticmethod
    def from_dict(obj: Any) -> 'Convert':
        assert isinstance(obj, dict)
        return Convert()

    def to_dict(self) -> dict:
        result: dict = {}
        return result


def test_from_dict(s: Any) -> Test:
    return Test.from_dict(s)


def test_to_dict(x: Test) -> Any:
    return to_class(Test, x)


def convert_from_dict(s: Any) -> Convert:
    return Convert.from_dict(s)


def convert_to_dict(x: Convert) -> Any:
    return to_class(Convert, x)
