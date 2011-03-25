function toggleShowHide(boxName, divName) 
{
	if (document.getElementById(boxName).checked==true)
	{
		document.getElementById(divName).style.visibility = 'hidden';
		document.getElementById(divName).style.display = 'none';
	}
	else
	{
		document.getElementById(divName).style.visibility = 'visible';
		document.getElementById(divName).style.display = 'block';
	}
}

function finalize(divName)
{
	var inputArr = document.getElementById(divName).getElementsByTagName( "input" );
	
	//the first item found will be the finalize button, so we start at i=1
	for (var i = 1; i < inputArr.length; i++)
	{
		inputArr[i].style.visibility = 'hidden';
		inputArr[i].style.display = 'none';
		var toShow = ("div" + divName.charAt(divName.length-1) + "text" + (inputArr[i].id).charAt((inputArr[i].id).length-1));

		alert(toShow);
		document.getElementById(toShow).style.visibility = 'visible';
		document.getElementById(toShow).style.display = 'block';
		document.getElementById(toShow).firstChild.nodeValue = inputArr[i].value;
	
	}
}
