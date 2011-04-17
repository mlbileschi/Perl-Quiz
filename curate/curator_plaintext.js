function toggleShowHide(boxName, divId) 
{
	if (document.getElementById(boxName).checked==true)
	{
		document.getElementById(divId).style.visibility = 'hidden';
		document.getElementById(divId).style.display = 'none';
	}
	else
	{
		document.getElementById(divId).style.visibility = 'visible';
		document.getElementById(divId).style.display = 'block';
	}
}

function finalize(divId)
{
	var inputArr = document.getElementById(divId).getElementsByTagName( "input" );
	
	//the first item found will be the finalize button, so we start at i=1
	for (var i = 1; i < inputArr.length; i++)
	{
		inputArr[i].style.visibility = 'hidden';
		inputArr[i].style.display = 'none';
		var toAppend = (inputArr[i].id).substr((inputArr[i].name).indexOf("text\d")+5);
		var toShow = ("div" + divId.substr(8) + "text" + (inputArr[i].name).substr(7));

		//alert(toShow); //debug
		document.getElementById(toShow).style.visibility = 'visible';
		document.getElementById(toShow).style.display = 'block';
		document.getElementById(toShow).firstChild.nodeValue = inputArr[i].value;
	}
	//to hide the show hide tickbox
	inputArr[0].style.visibility = 'hidden';
	inputArr[0].style.display = 'none';
}


function finalizeAll()
{
	var inputArr = document.getElementsByTagName( "input" );

	for (var i = 0; i < inputArr.length; i++)
	{
		if (inputArr[i].parentNode.id!="") finalize(inputArr[i].parentNode.id);
		if (inputArr[i].name=="finalizeOne")
		{
			inputArr[i].disabled=1;
			inputArr[i].style.visibility = 'hidden';
			inputArr[i].style.display = 'none';			
		}
		else if (inputArr[i].type=="checkbox")
		{
			inputArr[i].disabled=1;
			inputArr[i].style.visibility = 'hidden';
			inputArr[i].style.display = 'none';	
		}
	}
}


